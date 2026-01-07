# Kubernetes Resources for Keycloak Deployment

# Namespace
resource "kubernetes_namespace" "keycloak" {
  count = var.create_namespace ? 1 : 0

  metadata {
    name   = var.namespace
    labels = local.common_labels
  }
}

# ConfigMap for .env file
resource "kubernetes_config_map" "keycloak_env" {
  metadata {
    name      = "${local.name_prefix}-keycloak-env"
    namespace = var.namespace
    labels    = local.common_labels
  }

  data = {
    ".env" = local.env_file_content
  }

  depends_on = [kubernetes_namespace.keycloak]
}

# Secret for database password
resource "kubernetes_secret" "keycloak_db" {
  metadata {
    name      = "${local.name_prefix}-keycloak-db"
    namespace = var.namespace
    labels    = local.common_labels
  }

  data = {
    password = var.db_password_secret_name != "" ? local.db_password : ""
  }

  type = "Opaque"

  depends_on = [kubernetes_namespace.keycloak]
}

# Secret for Keycloak admin password
resource "kubernetes_secret" "keycloak_admin" {
  metadata {
    name      = "${local.name_prefix}-keycloak-admin"
    namespace = var.namespace
    labels    = local.common_labels
  }

  data = {
    password = var.keycloak_admin_password_secret_name != "" ? data.aws_secretsmanager_secret_version.admin_password[0].secret_string : ""
  }

  type = "Opaque"

  depends_on = [kubernetes_namespace.keycloak]
}

# Deployment
resource "kubernetes_deployment" "keycloak" {
  metadata {
    name      = "${local.name_prefix}-keycloak"
    namespace = var.namespace
    labels    = local.common_labels
  }

  spec {
    replicas = var.replicas

    selector {
      match_labels = {
        "app.kubernetes.io/name"     = "keycloak"
        "app.kubernetes.io/instance" = var.environment
      }
    }

    template {
      metadata {
        labels = local.common_labels
        annotations = {
          "prometheus.io/scrape" = "true"
          "prometheus.io/port"   = "8080"
          "prometheus.io/path"   = "/metrics"
        }
      }

      spec {
        # Init container to create .env file with secrets
        init_container {
          name  = "setup-env"
          image = "busybox:latest"
          
          command = ["/bin/sh", "-c"]
          args = [
            <<-EOF
            echo "Creating .env file with secrets..."
            cp /tmp/env-template/.env /opt/keycloak/.env.tmp
            
            # Replace keycloak admin password placeholder
            sed -i "s|KEYCLOAK_ADMIN_PASSWORD=<from-secret>|KEYCLOAK_ADMIN_PASSWORD=$KEYCLOAK_ADMIN_PASSWORD|g" /opt/keycloak/.env.tmp
            
            # Replace postgres password placeholder  
            sed -i "s|POSTGRES_PASSWORD=<from-secret>|POSTGRES_PASSWORD=$POSTGRES_PASSWORD|g" /opt/keycloak/.env.tmp
            
            # Move to final location
            mv /opt/keycloak/.env.tmp /opt/keycloak/.env
            chmod 644 /opt/keycloak/.env
            
            echo ".env file created successfully"
            echo "--- .env file content (passwords masked) ---"
            cat /opt/keycloak/.env | sed 's/PASSWORD=.*/PASSWORD=***MASKED***/g'
            EOF
          ]
          
          env {
            name = "KEYCLOAK_ADMIN_PASSWORD"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.keycloak_admin.metadata[0].name
                key  = "password"
              }
            }
          }
          
          env {
            name = "POSTGRES_PASSWORD"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.keycloak_db.metadata[0].name
                key  = "password"
              }
            }
          }
          
          volume_mount {
            name       = "env-template"
            mount_path = "/tmp/env-template"
            read_only  = true
          }
          
          volume_mount {
            name       = "env-file"
            mount_path = "/opt/keycloak"
          }
        }

        container {
          name  = "keycloak"
          image = local.image_uri

          # Command to source .env file before starting Keycloak
          command = ["/bin/sh", "-c"]
          args = [
            <<-EOF
            set -a
            if [ -f /opt/keycloak/.env ]; then
              echo "Loading and exporting environment variables from /opt/keycloak/.env"
              source /opt/keycloak/.env
            else
              echo "Warning: /opt/keycloak/.env not found"
            fi
            set +a
            
            echo "Starting Keycloak..."
            exec /opt/keycloak/bin/kc.sh start
            EOF
          ]

          port {
            name           = "http"
            container_port = var.container_port
            protocol       = "TCP"
          }

          # Environment variable to point to .env file location
          env {
            name  = "ENV_FILE"
            value = "/opt/keycloak/.env"
          }

          dynamic "env" {
            for_each = local.container_env_vars
            content {
              name  = env.key
              value = env.value
            }
          }

          # Database password from secret
          env {
            name = "KC_DB_PASSWORD"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.keycloak_db.metadata[0].name
                key  = "password"
              }
            }
          }

          # Admin password from secret
          env {
            name = "KEYCLOAK_ADMIN_PASSWORD"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.keycloak_admin.metadata[0].name
                key  = "password"
              }
            }
          }

          resources {
            requests = {
              cpu    = var.cpu_request
              memory = var.memory_request
            }
            limits = {
              cpu    = var.cpu_limit
              memory = var.memory_limit
            }
          }

          liveness_probe {
            http_get {
              path = "/health/live"
              port = var.container_port
            }
            initial_delay_seconds = 60
            period_seconds        = 15
            timeout_seconds       = 5
            failure_threshold     = 3
          }

          readiness_probe {
            http_get {
              path = var.health_check_path
              port = var.container_port
            }
            initial_delay_seconds = 30
            period_seconds        = 10
            timeout_seconds       = 5
            failure_threshold     = 3
          }

          security_context {
            read_only_root_filesystem = false
            run_as_non_root           = true
            run_as_user               = 1000
            allow_privilege_escalation = false
          }

          # Mount .env file from shared volume
          volume_mount {
            name       = "env-file"
            mount_path = "/opt/keycloak/.env"
            sub_path   = ".env"
            read_only  = true
          }
        }

        restart_policy = "Always"

        # Volume for .env template from ConfigMap
        volume {
          name = "env-template"
          config_map {
            name = kubernetes_config_map.keycloak_env.metadata[0].name
          }
        }

        # Shared volume for processed .env file
        volume {
          name = "env-file"
          empty_dir {}
        }

        security_context {
          fs_group = 1000
        }
      }
    }

    strategy {
      type = "RollingUpdate"
      rolling_update {
        max_surge       = 1
        max_unavailable = 0
      }
    }
  }

  depends_on = [kubernetes_namespace.keycloak]
}

# Service
resource "kubernetes_service" "keycloak" {
  metadata {
    name      = "${local.name_prefix}-keycloak"
    namespace = var.namespace
    labels    = local.common_labels
  }

  spec {
    selector = {
      "app.kubernetes.io/name"     = "keycloak"
      "app.kubernetes.io/instance" = var.environment
    }

    port {
      name        = "http"
      port        = 80
      target_port = var.container_port
      protocol    = "TCP"
    }

    type = "ClusterIP"
  }

  depends_on = [kubernetes_namespace.keycloak]
}

# Ingress (AWS ALB)
resource "kubernetes_ingress_v1" "keycloak" {
  count = var.create_ingress ? 1 : 0

  metadata {
    name      = "${local.name_prefix}-keycloak"
    namespace = var.namespace
    labels    = local.common_labels

    annotations = merge({
      "kubernetes.io/ingress.class"                       = var.ingress_class
      "alb.ingress.kubernetes.io/scheme"                  = var.alb_scheme
      "alb.ingress.kubernetes.io/target-type"             = var.alb_target_type
      "alb.ingress.kubernetes.io/subnets"                 = local.subnet_ids_string
      "alb.ingress.kubernetes.io/certificate-arn"         = local.certificate_arn
      "alb.ingress.kubernetes.io/listen-ports"            = "[{\"HTTP\": 80}, {\"HTTPS\": 443}]"
      "alb.ingress.kubernetes.io/ssl-redirect"            = "443"
      "alb.ingress.kubernetes.io/healthcheck-path"        = var.health_check_path
      "alb.ingress.kubernetes.io/healthcheck-protocol"    = "HTTP"
      "alb.ingress.kubernetes.io/success-codes"           = "200"
      "alb.ingress.kubernetes.io/tags"                    = "Environment=nonprod,Application=${var.app_name},Component=idm"
      "alb.ingress.kubernetes.io/target-group-attributes" = "stickiness.enabled=true,stickiness.lb_cookie.duration_seconds=86400"
      },
      var.alb_group_name != "" ? {
        "alb.ingress.kubernetes.io/group.name" = var.alb_group_name
      } : {}
    )
  }

  spec {
    ingress_class_name = var.ingress_class

    rule {
      host = var.domain_name

      http {
        path {
          path      = "/"
          path_type = "Prefix"

          backend {
            service {
              name = kubernetes_service.keycloak.metadata[0].name
              port {
                number = 80
              }
            }
          }
        }
      }
    }

    dynamic "tls" {
      for_each = local.certificate_arn != "" ? [1] : []
      content {
        hosts = [var.domain_name]
      }
    }
  }

  depends_on = [kubernetes_service.keycloak]
}
