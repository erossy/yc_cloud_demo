terraform {
  required_providers {
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
  }
}

resource "kubernetes_daemon_set_v1" "lab-demo-daemonset" {
  metadata {
    name      = "lab-demo"
    namespace = "default"
    labels = {
      app-label = "lab-demo-label"
    }
  }

  spec {
    selector {
      match_labels = {
        app-label = "lab-demo-label"
      }
    }

    template {
      metadata {
        labels = {
          app-label = "lab-demo-label"
        }
      }

      spec {
        container {
          image = "${var.yc_cr_id}/sample-image:latest"
          name  = "lab-demo-app"
          port {
            container_port = 5000
          }
          env {
            name = "db_password"
            value = "${var.yc_db_password}"
          }
          env {
            name = "db_user"
            value = "${var.yc_db_user}"
          }
          env {
            name = "db_name"
            value = "${var.yc_db_name}"
          }
          env {
            name = "db_host"
            value = "c-${var.yc_db_host}.rw.mdb.yandexcloud.net"
          }

        }
      }
    }
  }
}

resource "kubernetes_service_v1" "lab-demo-nlb" {
  metadata {
    name      = "lab-demo"
    namespace = "default"
    labels = {
      app-label = "lab-demo-label"
    }
  }
  spec {
    selector = {
        app-label = "lab-demo-label"
    }
    port {
      port        = 80
      target_port = 5000
    }
    type = "LoadBalancer"
  }
}