resource "kubernetes_namespace" "prow" {
  metadata {
    name = "prow"
  }
}

resource "kubernetes_config_map" "plugins" {
  data = {
    "plugins.yaml" = var.plugin_config_raw
  }

  metadata {
    name      = "plugins"
    namespace = "prow"
  }
}

resource "kubernetes_secret" "github_token" {
  data = {
    cert  = var.github_cert
    appid = var.github_appid
  }

  metadata {
    name      = "github-token"
    namespace = "prow"
  }
}

resource "kubernetes_secret" "hmac_token" {
  data = {
    hmac = var.hmac_token
  }

  metadata {
    name      = "hmac-token"
    namespace = "prow"
  }
}

resource "kubernetes_config_map" "config" {
  data = {
    "config.yaml" = var.prow_config_raw
  }

  metadata {
    name      = "config"
    namespace = "prow"
  }
}

resource "kubernetes_deployment" "hook" {
  metadata {
    name      = "hook"
    namespace = "prow"

    labels = {
      app = "hook"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "hook"
      }
    }

    template {
      metadata {
        labels = {
          app = "hook"
        }
      }

      spec {
        volume {
          name = "hmac"

          secret {
            secret_name = "hmac-token"
          }
        }

        volume {
          name = "github-token"

          secret {
            secret_name = "github-token"
          }
        }

        volume {
          name = "config"

          config_map {
            name = "config"
          }
        }

        volume {
          name = "plugins"

          config_map {
            name = "plugins"
          }
        }

        container {
          name  = "hook"
          image = "gcr.io/k8s-prow/hook:v20220923-6963e8f005"
          args  = ["--dry-run=false", "--config-path=/etc/config/config.yaml", "--github-endpoint=http://ghproxy", "--github-endpoint=https://api.github.com", "--github-app-id=$(GITHUB_APP_ID)", "--github-app-private-key-path=/etc/github/cert"]

          port {
            name           = "http"
            container_port = 8888
          }

          env {
            name = "GITHUB_APP_ID"

            value_from {
              secret_key_ref {
                name = "github-token"
                key  = "appid"
              }
            }
          }

          volume_mount {
            name       = "hmac"
            read_only  = true
            mount_path = "/etc/webhook"
          }

          volume_mount {
            name       = "github-token"
            read_only  = true
            mount_path = "/etc/github"
          }

          volume_mount {
            name       = "config"
            read_only  = true
            mount_path = "/etc/config"
          }

          volume_mount {
            name       = "plugins"
            read_only  = true
            mount_path = "/etc/plugins"
          }

          liveness_probe {
            http_get {
              path = "/healthz"
              port = "8081"
            }

            initial_delay_seconds = 3
            period_seconds        = 3
          }

          readiness_probe {
            http_get {
              path = "/healthz/ready"
              port = "8081"
            }

            initial_delay_seconds = 10
            timeout_seconds       = 600
            period_seconds        = 3
          }

          image_pull_policy = "Always"
        }

        termination_grace_period_seconds = 180
        service_account_name             = "hook"
      }
    }

    strategy {
      type = "RollingUpdate"

      rolling_update {
        max_unavailable = "1"
        max_surge       = "1"
      }
    }
  }
}

resource "kubernetes_service" "hook" {
  metadata {
    name      = "hook"
    namespace = "prow"
  }

  spec {
    port {
      port = 8888
    }

    selector = {
      app = "hook"
    }
  }
}

resource "kubernetes_deployment" "sinker" {
  metadata {
    name      = "sinker"
    namespace = "prow"

    labels = {
      app = "sinker"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "sinker"
      }
    }

    template {
      metadata {
        labels = {
          app = "sinker"
        }
      }

      spec {
        volume {
          name = "config"

          config_map {
            name = "config"
          }
        }

        container {
          name  = "sinker"
          image = "gcr.io/k8s-prow/sinker:v20220923-6963e8f005"
          args  = ["--config-path=/etc/config/config.yaml", "--dry-run=false"]

          volume_mount {
            name       = "config"
            read_only  = true
            mount_path = "/etc/config"
          }
        }

        service_account_name = "sinker"
      }
    }
  }
}

resource "kubernetes_deployment" "deck" {
  metadata {
    name      = "deck"
    namespace = "prow"

    labels = {
      app = "deck"
    }
  }

  spec {
    replicas = 2

    selector {
      match_labels = {
        app = "deck"
      }
    }

    template {
      metadata {
        labels = {
          app = "deck"
        }
      }

      spec {
        volume {
          name = "config"

          config_map {
            name = "config"
          }
        }

        volume {
          name = "github-token"

          secret {
            secret_name = "github-token"
          }
        }

        volume {
          name = "plugins"

          config_map {
            name = "plugins"
          }
        }

        volume {
          name = "s3-credentials"

          secret {
            secret_name = "s3-credentials"
          }
        }

        container {
          name  = "deck"
          image = "gcr.io/k8s-prow/deck:v20220923-6963e8f005"
          args  = ["--config-path=/etc/config/config.yaml", "--plugin-config=/etc/plugins/plugins.yaml", "--tide-url=http://tide/", "--hook-url=http://hook:8888/plugin-help", "--github-endpoint=http://ghproxy", "--github-endpoint=https://api.github.com", "--github-graphql-endpoint=http://ghproxy/graphql", "--s3-credentials-file=/etc/s3-credentials/service-account.json", "--spyglass=true", "--github-app-id=$(GITHUB_APP_ID)", "--github-app-private-key-path=/etc/github/cert"]

          port {
            name           = "http"
            container_port = 8080
          }

          env {
            name = "GITHUB_APP_ID"

            value_from {
              secret_key_ref {
                name = "github-token"
                key  = "appid"
              }
            }
          }

          volume_mount {
            name       = "config"
            read_only  = true
            mount_path = "/etc/config"
          }

          volume_mount {
            name       = "github-token"
            read_only  = true
            mount_path = "/etc/github"
          }

          volume_mount {
            name       = "plugins"
            read_only  = true
            mount_path = "/etc/plugins"
          }

          volume_mount {
            name       = "s3-credentials"
            read_only  = true
            mount_path = "/etc/s3-credentials"
          }

          liveness_probe {
            http_get {
              path = "/healthz"
              port = "8081"
            }

            initial_delay_seconds = 3
            period_seconds        = 3
          }

          readiness_probe {
            http_get {
              path = "/healthz/ready"
              port = "8081"
            }

            initial_delay_seconds = 10
            timeout_seconds       = 600
            period_seconds        = 3
          }
        }

        termination_grace_period_seconds = 30
        service_account_name             = "deck"
      }
    }

    strategy {
      type = "RollingUpdate"

      rolling_update {
        max_unavailable = "1"
        max_surge       = "1"
      }
    }
  }
}

resource "kubernetes_service" "deck" {
  metadata {
    name      = "deck"
    namespace = "prow"
  }

  spec {
    port {
      port        = 80
      target_port = "8080"
    }

    selector = {
      app = "deck"
    }
  }
}

resource "kubernetes_deployment" "horologium" {
  metadata {
    name      = "horologium"
    namespace = "prow"

    labels = {
      app = "horologium"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "horologium"
      }
    }

    template {
      metadata {
        labels = {
          app = "horologium"
        }
      }

      spec {
        volume {
          name = "config"

          config_map {
            name = "config"
          }
        }

        container {
          name  = "horologium"
          image = "gcr.io/k8s-prow/horologium:v20220923-6963e8f005"
          args  = ["--dry-run=false", "--config-path=/etc/config/config.yaml"]

          volume_mount {
            name       = "config"
            read_only  = true
            mount_path = "/etc/config"
          }
        }

        termination_grace_period_seconds = 30
        service_account_name             = "horologium"
      }
    }

    strategy {
      type = "Recreate"
    }
  }
}

resource "kubernetes_deployment" "tide" {
  metadata {
    name      = "tide"
    namespace = "prow"

    labels = {
      app = "tide"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "tide"
      }
    }

    template {
      metadata {
        labels = {
          app = "tide"
        }
      }

      spec {
        volume {
          name = "github-token"

          secret {
            secret_name = "github-token"
          }
        }

        volume {
          name = "config"

          config_map {
            name = "config"
          }
        }

        volume {
          name = "s3-credentials"

          secret {
            secret_name = "s3-credentials"
          }
        }

        container {
          name  = "tide"
          image = "gcr.io/k8s-prow/tide:v20220923-6963e8f005"
          args  = ["--dry-run=false", "--config-path=/etc/config/config.yaml", "--github-endpoint=http://ghproxy", "--github-endpoint=https://api.github.com", "--github-graphql-endpoint=http://ghproxy/graphql", "--s3-credentials-file=/etc/s3-credentials/service-account.json", "--status-path=s3://tide/tide-status", "--history-uri=s3://tide/tide-history.json", "--github-app-id=$(GITHUB_APP_ID)", "--github-app-private-key-path=/etc/github/cert"]

          port {
            name           = "http"
            container_port = 8888
          }

          env {
            name = "GITHUB_APP_ID"

            value_from {
              secret_key_ref {
                name = "github-token"
                key  = "appid"
              }
            }
          }

          volume_mount {
            name       = "github-token"
            read_only  = true
            mount_path = "/etc/github"
          }

          volume_mount {
            name       = "config"
            read_only  = true
            mount_path = "/etc/config"
          }

          volume_mount {
            name       = "s3-credentials"
            read_only  = true
            mount_path = "/etc/s3-credentials"
          }
        }

        service_account_name = "tide"
      }
    }

    strategy {
      type = "Recreate"
    }
  }
}

resource "kubernetes_service" "tide" {
  metadata {
    name      = "tide"
    namespace = "prow"
  }

  spec {
    port {
      port        = 80
      target_port = "8888"
    }

    selector = {
      app = "tide"
    }
  }
}

resource "kubernetes_ingress_v1" "prow" {
  metadata {
    name      = "prow"
    namespace = "prow"

    annotations = {
      "cert-manager.io/cluster-issuer" = "letsencrypt-staging"
    }
  }

  spec {
    ingress_class_name = "nginx"

    default_backend {
      service {
        name = "deck"

        port {
          number = 80
        }
      }
    }

    rule {
      host = "prow.${var.domain}"

      http {
        path {
          path      = "/"
          path_type = "Prefix"

          backend {
            service {
              name = "deck"

              port {
                number = 80
              }
            }
          }
        }

        path {
          path      = "/hook"
          path_type = "Prefix"

          backend {
            service {
              name = "hook"

              port {
                number = 8888
              }
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_deployment" "statusreconciler" {
  metadata {
    name      = "statusreconciler"
    namespace = "prow"

    labels = {
      app = "statusreconciler"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "statusreconciler"
      }
    }

    template {
      metadata {
        labels = {
          app = "statusreconciler"
        }
      }

      spec {
        volume {
          name = "github-token"

          secret {
            secret_name = "github-token"
          }
        }

        volume {
          name = "config"

          config_map {
            name = "config"
          }
        }

        volume {
          name = "plugins"

          config_map {
            name = "plugins"
          }
        }

        volume {
          name = "s3-credentials"

          secret {
            secret_name = "s3-credentials"
          }
        }

        container {
          name  = "statusreconciler"
          image = "gcr.io/k8s-prow/status-reconciler:v20220923-6963e8f005"
          args  = ["--dry-run=false", "--continue-on-error=true", "--plugin-config=/etc/plugins/plugins.yaml", "--config-path=/etc/config/config.yaml", "--github-endpoint=http://ghproxy", "--github-endpoint=https://api.github.com", "--s3-credentials-file=/etc/s3-credentials/service-account.json", "--status-path=s3://status-reconciler/status-reconciler-status", "--github-app-id=$(GITHUB_APP_ID)", "--github-app-private-key-path=/etc/github/cert"]

          env {
            name = "GITHUB_APP_ID"

            value_from {
              secret_key_ref {
                name = "github-token"
                key  = "appid"
              }
            }
          }

          volume_mount {
            name       = "github-token"
            read_only  = true
            mount_path = "/etc/github"
          }

          volume_mount {
            name       = "config"
            read_only  = true
            mount_path = "/etc/config"
          }

          volume_mount {
            name       = "plugins"
            read_only  = true
            mount_path = "/etc/plugins"
          }

          volume_mount {
            name       = "s3-credentials"
            read_only  = true
            mount_path = "/etc/s3-credentials"
          }
        }

        termination_grace_period_seconds = 180
        service_account_name             = "statusreconciler"
      }
    }
  }
}

resource "kubernetes_namespace" "test_pods" {
  metadata {
    name = "test-pods"
  }
}

resource "kubernetes_service_account" "deck" {
  metadata {
    name      = "deck"
    namespace = "prow"
  }
}

resource "kubernetes_role_binding" "prow_deck" {
  metadata {
    name      = "deck"
    namespace = "prow"
  }

  subject {
    kind      = "ServiceAccount"
    name      = "deck"
    namespace = "prow"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = "deck"
  }
}

resource "kubernetes_role_binding" "test_pods_deck" {
  metadata {
    name      = "deck"
    namespace = "test-pods"
  }

  subject {
    kind      = "ServiceAccount"
    name      = "deck"
    namespace = "prow"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = "deck"
  }
}

resource "kubernetes_role" "prow_deck" {
  metadata {
    name      = "deck"
    namespace = "prow"
  }

  rule {
    verbs      = ["get", "list", "watch"]
    api_groups = ["prow.k8s.io"]
    resources  = ["prowjobs"]
  }
}

resource "kubernetes_role" "test_pods_deck" {
  metadata {
    name      = "deck"
    namespace = "test-pods"
  }

  rule {
    verbs      = ["get"]
    api_groups = [""]
    resources  = ["pods/log"]
  }
}

resource "kubernetes_service_account" "horologium" {
  metadata {
    name      = "horologium"
    namespace = "prow"
  }
}

resource "kubernetes_role" "prowhorologium" {
  metadata {
    name      = "horologium"
    namespace = "prow"
  }

  rule {
    verbs      = ["create", "list", "watch"]
    api_groups = ["prow.k8s.io"]
    resources  = ["prowjobs"]
  }
}

resource "kubernetes_role_binding" "horologium" {
  metadata {
    name      = "horologium"
    namespace = "prow"
  }

  subject {
    kind      = "ServiceAccount"
    name      = "horologium"
    namespace = "prow"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = "horologium"
  }
}

resource "kubernetes_service_account" "sinker" {
  metadata {
    name      = "sinker"
    namespace = "prow"
  }
}

resource "kubernetes_role" "prow_sinker" {
  metadata {
    name      = "sinker"
    namespace = "prow"
  }

  rule {
    verbs      = ["delete", "list", "watch", "get"]
    api_groups = ["prow.k8s.io"]
    resources  = ["prowjobs"]
  }

  rule {
    verbs          = ["get", "update"]
    api_groups     = ["coordination.k8s.io"]
    resources      = ["leases"]
    resource_names = ["prow-sinker-leaderlock"]
  }

  rule {
    verbs      = ["create"]
    api_groups = ["coordination.k8s.io"]
    resources  = ["leases"]
  }

  rule {
    verbs          = ["get", "update"]
    api_groups     = [""]
    resources      = ["configmaps"]
    resource_names = ["prow-sinker-leaderlock"]
  }

  rule {
    verbs      = ["create"]
    api_groups = [""]
    resources  = ["configmaps", "events"]
  }
}

resource "kubernetes_role" "test_pods_sinker" {
  metadata {
    name      = "sinker"
    namespace = "test-pods"
  }

  rule {
    verbs      = ["delete", "list", "watch", "get", "patch"]
    api_groups = [""]
    resources  = ["pods"]
  }
}

resource "kubernetes_role_binding" "prow_sinker" {
  metadata {
    name      = "sinker"
    namespace = "prow"
  }

  subject {
    kind      = "ServiceAccount"
    name      = "sinker"
    namespace = "prow"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = "sinker"
  }
}

resource "kubernetes_role_binding" "test_pods_sinker" {
  metadata {
    name      = "sinker"
    namespace = "test-pods"
  }

  subject {
    kind      = "ServiceAccount"
    name      = "sinker"
    namespace = "prow"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = "sinker"
  }
}

resource "kubernetes_service_account" "hook" {
  metadata {
    name      = "hook"
    namespace = "prow"
  }
}

resource "kubernetes_role" "hook" {
  metadata {
    name      = "hook"
    namespace = "prow"
  }

  rule {
    verbs      = ["create", "get", "list", "update"]
    api_groups = ["prow.k8s.io"]
    resources  = ["prowjobs"]
  }

  rule {
    verbs      = ["create", "get", "update"]
    api_groups = [""]
    resources  = ["configmaps"]
  }
}

resource "kubernetes_role_binding" "hook" {
  metadata {
    name      = "hook"
    namespace = "prow"
  }

  subject {
    kind      = "ServiceAccount"
    name      = "hook"
    namespace = "prow"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = "hook"
  }
}

resource "kubernetes_service_account" "tide" {
  metadata {
    name      = "tide"
    namespace = "prow"
  }
}

resource "kubernetes_role" "tide" {
  metadata {
    name      = "tide"
    namespace = "prow"
  }

  rule {
    verbs      = ["create", "list", "get", "watch"]
    api_groups = ["prow.k8s.io"]
    resources  = ["prowjobs"]
  }
}

resource "kubernetes_role_binding" "tide" {
  metadata {
    name      = "tide"
    namespace = "prow"
  }

  subject {
    kind      = "ServiceAccount"
    name      = "tide"
    namespace = "prow"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = "tide"
  }
}

resource "kubernetes_service_account" "statusreconciler" {
  metadata {
    name      = "statusreconciler"
    namespace = "prow"
  }
}

resource "kubernetes_role" "statusreconciler" {
  metadata {
    name      = "statusreconciler"
    namespace = "prow"
  }

  rule {
    verbs      = ["create"]
    api_groups = ["prow.k8s.io"]
    resources  = ["prowjobs"]
  }
}

resource "kubernetes_role_binding" "statusreconciler" {
  metadata {
    name      = "statusreconciler"
    namespace = "prow"
  }

  subject {
    kind      = "ServiceAccount"
    name      = "statusreconciler"
    namespace = "prow"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = "statusreconciler"
  }
}

resource "kubernetes_persistent_volume_claim" "ghproxy" {
  metadata {
    name      = "ghproxy"
    namespace = "prow"

    labels = {
      app = "ghproxy"
    }
  }

  spec {
    access_modes = ["ReadWriteOnce"]

    resources {
      requests = {
        storage = "100Gi"
      }
    }
  }
}

resource "kubernetes_deployment" "ghproxy" {
  metadata {
    name      = "ghproxy"
    namespace = "prow"

    labels = {
      app = "ghproxy"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "ghproxy"
      }
    }

    template {
      metadata {
        labels = {
          app = "ghproxy"
        }
      }

      spec {
        volume {
          name = "cache"

          persistent_volume_claim {
            claim_name = "ghproxy"
          }
        }

        container {
          name  = "ghproxy"
          image = "gcr.io/k8s-prow/ghproxy:v20220923-6963e8f005"
          args  = ["--cache-dir=/cache", "--cache-sizeGB=99", "--push-gateway=pushgateway", "--serve-metrics=true"]

          port {
            container_port = 8888
          }

          volume_mount {
            name       = "cache"
            mount_path = "/cache"
          }
        }
      }
    }

    strategy {
      type = "Recreate"
    }
  }
}

resource "kubernetes_service" "ghproxy" {
  metadata {
    name      = "ghproxy"
    namespace = "prow"

    labels = {
      app = "ghproxy"
    }
  }

  spec {
    port {
      name        = "main"
      protocol    = "TCP"
      port        = 80
      target_port = "8888"
    }

    port {
      name = "metrics"
      port = 9090
    }

    selector = {
      app = "ghproxy"
    }

    type = "ClusterIP"
  }
}

resource "kubernetes_deployment" "prow_controller_manager" {
  metadata {
    name      = "prow-controller-manager"
    namespace = "prow"

    labels = {
      app = "prow-controller-manager"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "prow-controller-manager"
      }
    }

    template {
      metadata {
        labels = {
          app = "prow-controller-manager"
        }
      }

      spec {
        volume {
          name = "github-token"

          secret {
            secret_name = "github-token"
          }
        }

        volume {
          name = "config"

          config_map {
            name = "config"
          }
        }

        container {
          name  = "prow-controller-manager"
          image = "gcr.io/k8s-prow/prow-controller-manager:v20220923-6963e8f005"
          args  = ["--dry-run=false", "--config-path=/etc/config/config.yaml", "--github-endpoint=http://ghproxy", "--github-endpoint=https://api.github.com", "--enable-controller=plank", "--github-app-id=$(GITHUB_APP_ID)", "--github-app-private-key-path=/etc/github/cert"]

          env {
            name = "GITHUB_APP_ID"

            value_from {
              secret_key_ref {
                name = "github-token"
                key  = "appid"
              }
            }
          }

          volume_mount {
            name       = "github-token"
            read_only  = true
            mount_path = "/etc/github"
          }

          volume_mount {
            name       = "config"
            read_only  = true
            mount_path = "/etc/config"
          }
        }

        service_account_name = "prow-controller-manager"
      }
    }
  }
}

resource "kubernetes_service_account" "prow_controller_manager" {
  metadata {
    name      = "prow-controller-manager"
    namespace = "prow"
  }
}

resource "kubernetes_role" "prow_controller_manager" {
  metadata {
    name      = "prow-controller-manager"
    namespace = "prow"
  }

  rule {
    verbs      = ["get", "list", "watch", "update", "patch"]
    api_groups = ["prow.k8s.io"]
    resources  = ["prowjobs"]
  }

  rule {
    verbs          = ["get", "update"]
    api_groups     = ["coordination.k8s.io"]
    resources      = ["leases"]
    resource_names = ["prow-controller-manager-leader-lock"]
  }

  rule {
    verbs      = ["create"]
    api_groups = ["coordination.k8s.io"]
    resources  = ["leases"]
  }

  rule {
    verbs          = ["get", "update"]
    api_groups     = [""]
    resources      = ["configmaps"]
    resource_names = ["prow-controller-manager-leader-lock"]
  }

  rule {
    verbs      = ["create"]
    api_groups = [""]
    resources  = ["configmaps", "events"]
  }
}

resource "kubernetes_role" "test_pods_prow_controller_manager" {
  metadata {
    name      = "prow-controller-manager"
    namespace = "test-pods"
  }

  rule {
    verbs      = ["delete", "list", "watch", "create", "patch"]
    api_groups = [""]
    resources  = ["pods"]
  }
}

resource "kubernetes_role_binding" "prow_controller_manager" {
  metadata {
    name      = "prow-controller-manager"
    namespace = "prow"
  }

  subject {
    kind      = "ServiceAccount"
    name      = "prow-controller-manager"
    namespace = "prow"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = "prow-controller-manager"
  }
}

resource "kubernetes_role_binding" "test_pods_prow_controller_manager" {
  metadata {
    name      = "prow-controller-manager"
    namespace = "test-pods"
  }

  subject {
    kind      = "ServiceAccount"
    name      = "prow-controller-manager"
    namespace = "prow"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = "prow-controller-manager"
  }
}

resource "kubernetes_deployment" "crier" {
  metadata {
    name      = "crier"
    namespace = "prow"

    labels = {
      app = "crier"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "crier"
      }
    }

    template {
      metadata {
        labels = {
          app = "crier"
        }
      }

      spec {
        termination_grace_period_seconds = 30
        service_account_name             = "crier"

        volume {
          name = "config"

          config_map {
            name = "config"
          }
        }
        volume {
          name = "github-token"

          secret {
            secret_name = "github-token"
          }
        }
        volume {
          name = "s3-credentials"

          secret {
            secret_name = "s3-credentials"
          }
        }
        container {
          name  = "crier"
          image = "gcr.io/k8s-prow/crier:v20220923-6963e8f005"
          args  = ["--blob-storage-workers=10", "--config-path=/etc/config/config.yaml", "--s3-credentials-file=/etc/s3-credentials/service-account.json", "--github-endpoint=http://ghproxy", "--github-endpoint=https://api.github.com", "--github-workers=10", "--kubernetes-blob-storage-workers=10", "--github-app-id=$(GITHUB_APP_ID)", "--github-app-private-key-path=/etc/github/cert"]

          env {
            name = "GITHUB_APP_ID"

            value_from {
              secret_key_ref {
                name = "github-token"
                key  = "appid"
              }
            }
          }
          volume_mount {
            name       = "config"
            read_only  = true
            mount_path = "/etc/config"
          }
          volume_mount {
            name       = "github-token"
            read_only  = true
            mount_path = "/etc/github"
          }
          volume_mount {
            name       = "s3-credentials"
            read_only  = true
            mount_path = "/etc/s3-credentials"
          }
        }
      }
    }
  }
}

resource "kubernetes_service_account" "crier" {
  metadata {
    name      = "crier"
    namespace = "prow"
  }
}

resource "kubernetes_role" "prow_crier" {
  metadata {
    name      = "crier"
    namespace = "prow"
  }

  rule {
    verbs      = ["get", "watch", "list", "patch"]
    api_groups = ["prow.k8s.io"]
    resources  = ["prowjobs"]
  }
}

resource "kubernetes_role" "test_pods_crier" {
  metadata {
    name      = "crier"
    namespace = "test-pods"
  }

  rule {
    verbs      = ["get", "list"]
    api_groups = [""]
    resources  = ["pods", "events"]
  }

  rule {
    verbs      = ["patch"]
    api_groups = [""]
    resources  = ["pods"]
  }
}

resource "kubernetes_role_binding" "prow_crier" {
  metadata {
    name      = "crier"
    namespace = "prow"
  }

  subject {
    kind      = "ServiceAccount"
    name      = "crier"
    namespace = "prow"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = "crier"
  }
}

resource "kubernetes_role_binding" "test_pods_crier" {
  metadata {
    name      = "crier"
    namespace = "test-pods"
  }

  subject {
    kind      = "ServiceAccount"
    name      = "crier"
    namespace = "prow"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = "crier"
  }
}

resource "kubernetes_persistent_volume_claim" "minio" {
  metadata {
    name      = "minio"
    namespace = "prow"
  }

  spec {
    access_modes = ["ReadWriteOnce"]

    resources {
      requests = {
        storage = "100Gi"
      }
    }
  }
}

resource "kubernetes_secret" "prow_s3_credentials" {
  data = {
    "service-account.json" = jsonencode({
      "region" : "minio",
      "access_key" : var.minio_root_user,
      "endpoint" : "minio.prow.svc.cluster.local",
      "insecure" : true,
      "s3_force_path_style" : true,
      "secret_key" : var.minio_root_password
    })
  }

  metadata {
    name      = "s3-credentials"
    namespace = "prow"
  }
}

resource "kubernetes_secret" "test_pods_prow_s3_credentials" {
  data = {
    "service-account.json" = jsonencode({
      "region" : "minio",
      "access_key" : var.minio_root_user,
      "endpoint" : "minio.prow.svc.cluster.local",
      "insecure" : true,
      "s3_force_path_style" : true,
      "secret_key" : var.minio_root_password
    })
  }

  metadata {
    name      = "s3-credentials"
    namespace = "test-pods"
  }
}

resource "kubernetes_deployment" "minio" {
  metadata {
    name      = "minio"
    namespace = "prow"
  }

  spec {
    selector {
      match_labels = {
        app = "minio"
      }
    }

    template {
      metadata {
        labels = {
          app = "minio"
        }
      }

      spec {
        volume {
          name = "data"

          persistent_volume_claim {
            claim_name = "minio"
          }
        }

        init_container {
          name    = "bucket-creator"
          image   = "alpine"
          command = ["mkdir", "-p", "/data/prow-logs", "/data/tide", "/data/status-reconciler"]

          volume_mount {
            name       = "data"
            mount_path = "/data"
          }
        }

        container {
          name  = "minio"
          image = "minio/minio:latest"
          args  = ["server", "/data"]

          port {
            container_port = 9000
          }

          env {
            name  = "MINIO_ROOT_USER"
            value = var.minio_root_user
          }

          env {
            name  = "MINIO_ROOT_PASSWORD"
            value = var.minio_root_password
          }

          env {
            name  = "MINIO_REGION_NAME"
            value = "minio"
          }

          volume_mount {
            name       = "data"
            mount_path = "/data"
          }

          liveness_probe {
            http_get {
              path = "/minio/health/live"
              port = "9000"
            }
          }

          readiness_probe {
            period_seconds = 20

            http_get {
              path = "/minio/health/ready"
              port = "9000"
            }
          }
        }
      }
    }

    strategy {
      type = "Recreate"
    }
  }
}

resource "kubernetes_service" "minio" {
  metadata {
    name      = "minio"
    namespace = "prow"
  }

  spec {
    selector = {
      app = "minio"
    }
    type = "ClusterIP"

    port {
      protocol    = "TCP"
      port        = 80
      target_port = "9000"
    }
  }
}

