terraform {
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = ">= 0.47.0"
    }
  }
}

resource "yandex_vpc_subnet" "subnet-1" {
  name           = "subnet1"
  zone           = "ru-central1-a"
  network_id     = var.yc_network_id
  v4_cidr_blocks = ["192.168.1.0/24"]
}

resource "yandex_vpc_subnet" "subnet-2" {
  name           = "subnet2"
  zone           = "ru-central1-b"
  network_id     = var.yc_network_id
  v4_cidr_blocks = ["192.168.2.0/24"]
}

resource "yandex_vpc_subnet" "subnet-3" {
  name           = "subnet3"
  zone           = "ru-central1-c"
  network_id     = var.yc_network_id
  v4_cidr_blocks = ["192.168.3.0/24"]
}

resource "yandex_vpc_security_group" "alb-sg" {
  name        = "alb-sg"
  network_id  = var.yc_network_id

  egress {
    protocol       = "ANY"
    description    = "any"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol       = "TCP"
    description    = "ext-http"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 80
  }

  ingress {
    protocol       = "TCP"
    description    = "ext-https"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 443
  }

  ingress {
    protocol       = "TCP"
    description    = "healthchecks"
    v4_cidr_blocks = ["198.18.235.0/24", "198.18.248.0/24"]
    port           = 30080
  }
}

resource "yandex_vpc_security_group" "alb-vm-sg" {
  name        = "alb-vm-sg"
  network_id  = var.yc_network_id

 egress {
    protocol       = "ANY"
    description    = "any"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol          = "TCP"
    description       = "balancer"
    security_group_id = yandex_vpc_security_group.alb-sg.id
    port              = 80
  }

   ingress {
    protocol          = "TCP"
    description       = "balancer"
    security_group_id = yandex_vpc_security_group.alb-sg.id
    port              = 5000
  }

  ingress {
    protocol       = "TCP"
    description    = "ssh"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 22
  }

//Test if service works for LB thsooting
  #  ingress {
  #  protocol       = "TCP"
  #  description    = "5000"
  #  v4_cidr_blocks = ["0.0.0.0/0"]
  #  port           = 5000
  #}
}

resource "yandex_compute_image" "container-optimized-image" {
  source_family = "container-optimized-image"
}

resource "yandex_compute_instance_group" "alb-vm-group" {
  name               = "alb-vm-group"
  folder_id          = var.folder_id
  service_account_id = var.service_account_id
  instance_template {
    platform_id        = "standard-v2"
    service_account_id = var.service_account_id
    resources {
      core_fraction = 5
      memory        = 1
      cores         = 2
    }

    boot_disk {
      mode = "READ_WRITE"
      initialize_params {
        image_id = yandex_compute_image.container-optimized-image.id
        type     = "network-hdd"
        size     = 64
      }
    }

    network_interface {
      network_id         = var.yc_network_id
      subnet_ids         = [yandex_vpc_subnet.subnet-1.id,yandex_vpc_subnet.subnet-2.id,yandex_vpc_subnet.subnet-3.id]
      nat                = true
      security_group_ids = [yandex_vpc_security_group.alb-vm-sg.id]
    }

 metadata                  = {
        "docker-container-declaration" = <<-EOT
            spec:
              containers:
              - command:
                - python
                args:
                - ./run.py
                name: flask-app
                image: ${var.yc_cr_id}/sample-image:latest
                env:
                - name: db_password
                  value: ${var.yc_db_password}
                - name: db_user
                  value: ${var.yc_db_user}
                - name: db_name
                  value: ${var.yc_db_name}
                - name: db_host
                  value: c-${var.yc_db_host}.rw.mdb.yandexcloud.net
        EOT
        "serial-port-enable"           = "0"
        "ssh-keys"                     = "${var.vm_ssh_key_label}"
        "user-data"                    = <<-EOT
            #cloud-config
            datasource:
             Ec2:
              strict_id: false
            ssh_pwauth: no
            users:
            - name: ${var.ssh_username}
              sudo: ALL=(ALL) NOPASSWD:ALL
              shell: /bin/bash
              ssh_authorized_keys:
              - ${var.ssh_publickey}
        EOT

    }
  }

  scale_policy {
    fixed_scale {
      size = 3
    }
  }

  allocation_policy {
    zones = ["ru-central1-a", "ru-central1-b", "ru-central1-c"]
  }

  deploy_policy {
    max_unavailable = 3
    max_expansion   = 0
  }

  application_load_balancer {
    target_group_name = "alb-tg"
  }
}

resource "yandex_alb_backend_group" "alb-bg" {
  name                     = "alb-bg"

  http_backend {
    name                   = "backend-1"
    port                   = 5000
    target_group_ids       = [yandex_compute_instance_group.alb-vm-group.application_load_balancer.0.target_group_id]
    healthcheck {
      timeout              = "10s"
      interval             = "2s"
      healthcheck_port     = 5000
      http_healthcheck {
       path               = "/hello"
     }
    }
  }
}

resource "yandex_alb_http_router" "alb-router" {
  name   = "alb-router"
}

resource "yandex_alb_virtual_host" "alb-host" {
  name           = "alb-host"
  http_router_id = yandex_alb_http_router.alb-router.id
  #authority      = ["alb-example.com"]
  route {
    name = "route-1"
    http_route {
      http_route_action {
        backend_group_id = yandex_alb_backend_group.alb-bg.id
      }
    }
  }
}

resource "yandex_alb_load_balancer" "alb-1" {
  name               = "alb-1"
  network_id         = var.yc_network_id
  security_group_ids = [yandex_vpc_security_group.alb-sg.id]

  allocation_policy {
    location {
      zone_id   = "ru-central1-a"
      subnet_id = yandex_vpc_subnet.subnet-1.id
    }

    location {
      zone_id   = "ru-central1-b"
      subnet_id = yandex_vpc_subnet.subnet-2.id
    }

    location {
      zone_id   = "ru-central1-c"
      subnet_id = yandex_vpc_subnet.subnet-3.id
    }
  }

  listener {
    name = "alb-listener"
    endpoint {
      address {
        external_ipv4_address {
        }
      }
      ports = [ 80 ]
    }
    http {
      handler {
        http_router_id = yandex_alb_http_router.alb-router.id
      }
    }
  }
}

resource "yandex_dns_zone" "alb-zone" {
  name        = "alb-zone"
  description = "Public zone"
  zone        = "alb-example.com."
  public      = true
}

resource "yandex_dns_recordset" "rs-1" {
  zone_id = yandex_dns_zone.alb-zone.id
  name    = "alb-example.com."
  ttl     = 600
  type    = "A"
  data    = [yandex_alb_load_balancer.alb-1.listener[0].endpoint[0].address[0].external_ipv4_address[0].address]
}

resource "yandex_dns_recordset" "rs-2" {
  zone_id = yandex_dns_zone.alb-zone.id
  name    = "www"
  ttl     = 600
  type    = "CNAME"
  data    = ["alb-example.com"]
}