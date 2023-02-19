terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
  required_version = ">= 0.13"
}

resource "yandex_kubernetes_cluster" "k8s-regional" {
  network_id = var.yc_network_id
  master {
    public_ip = true
    version = var.k8s_version
    regional {
      region = "ru-central1"
      location {
        zone      = yandex_vpc_subnet.mysubnet-a.zone
        subnet_id = yandex_vpc_subnet.mysubnet-a.id
      }
      location {
        zone      = yandex_vpc_subnet.mysubnet-b.zone
        subnet_id = yandex_vpc_subnet.mysubnet-b.id
      }
      location {
        zone      = yandex_vpc_subnet.mysubnet-c.zone
        subnet_id = yandex_vpc_subnet.mysubnet-c.id
      }
    }
    security_group_ids = [yandex_vpc_security_group.k8s-main-sg.id, yandex_vpc_security_group.k8s-mgmt-sg.id]
  }
  service_account_id      = var.service_account_id
  node_service_account_id = var.service_account_id

  kms_provider {
    key_id = var.kms_key_id
  }
}

resource "yandex_vpc_subnet" "mysubnet-a" {
  v4_cidr_blocks = ["10.5.0.0/16"]
  zone           = "ru-central1-a"
  network_id     = var.yc_network_id
}

resource "yandex_vpc_subnet" "mysubnet-b" {
  v4_cidr_blocks = ["10.6.0.0/16"]
  zone           = "ru-central1-b"
  network_id     = var.yc_network_id
}

resource "yandex_vpc_subnet" "mysubnet-c" {
  v4_cidr_blocks = ["10.7.0.0/16"]
  zone           = "ru-central1-c"
  network_id     = var.yc_network_id
}


resource "yandex_vpc_security_group" "k8s-main-sg" {
  name        = "k8s-main-sg"
  description = "Group rules ensure the basic performance of the cluster. Apply it to the cluster and node groups."
  network_id  = var.yc_network_id
  ingress {
    protocol          = "TCP"
    description       = "Rule allows availability checks from load balancer's address range. It is required for the operation of a fault-tolerant cluster and load balancer services."
    predefined_target = "loadbalancer_healthchecks"
    from_port         = 0
    to_port           = 65535
  }
    ingress {
    protocol          = "TCP"
    description       = "Rule allows availability checks from load balancer's address range. It is required for the operation of a fault-tolerant cluster and load balancer services."
    v4_cidr_blocks    = ["0.0.0.0/0"]
    from_port         = 80
    to_port           = 80
  }
  ingress {
    protocol          = "ANY"
    description       = "Rule allows master-node and node-node communication inside a security group."
    predefined_target = "self_security_group"
    from_port         = 0
    to_port           = 65535
  }
  ingress {
    protocol          = "ANY"
    description       = "Rule allows pod-pod and service-service communication. Specify the subnets of your cluster and services."
    v4_cidr_blocks    = concat(yandex_vpc_subnet.mysubnet-a.v4_cidr_blocks, yandex_vpc_subnet.mysubnet-b.v4_cidr_blocks, yandex_vpc_subnet.mysubnet-c.v4_cidr_blocks)
    from_port         = 0
    to_port           = 65535
  }
  ingress {
    protocol          = "ICMP"
    description       = "Rule allows debugging ICMP packets from internal subnets."
    v4_cidr_blocks    = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]
  }
  ingress {
    protocol          = "TCP"
    description       = "Rule allows incoming traffic from the internet to the NodePort port range. Add ports or change existing ones to the required ports."
    v4_cidr_blocks    = ["0.0.0.0/0"]
    from_port         = 30000
    to_port           = 32767
  }
  egress {
    protocol          = "ANY"
    description       = "Rule allows all outgoing traffic. Nodes can connect to Yandex Container Registry, Yandex Object Storage, Docker Hub, and so on."
    v4_cidr_blocks    = ["0.0.0.0/0"]
    from_port         = 0
    to_port           = 65535
  }
}

resource "yandex_vpc_security_group" "k8s-mgmt-sg" {  #The rules could be more sec
  name        = "k8s-mgmt-sg"
  description = "Group for managing the cluster"
  network_id  = var.yc_network_id
  ingress {
    protocol          = "TCP"
    description       = "Management rule"
    from_port         = 443
    to_port           = 443
    v4_cidr_blocks    = ["0.0.0.0/0"]
  }
}

resource "yandex_kubernetes_node_group" "labng" {
    allowed_unsafe_sysctls = []
    cluster_id             = yandex_kubernetes_cluster.k8s-regional.id
    description            = "Node_Group_For_Lab"
    name                   = "labng"
    version                = "1.22"

    allocation_policy {
        location {
            #subnet_id = yandex_vpc_subnet.mysubnet-a.id
            zone      = "ru-central1-a"
        }
        location {
            #subnet_id = yandex_vpc_subnet.mysubnet-b.id
            zone      = "ru-central1-b"
        }
        location {
            #subnet_id = yandex_vpc_subnet.mysubnet-c.id
            zone      = "ru-central1-c"
        }
    }

    deploy_policy {
        max_expansion   = 3
        max_unavailable = 0
    }

    instance_template {
        labels                    = {}
        metadata                  = {
            "ssh-keys" = var.vm_ssh_key_label
        }
        #network_acceleration_type = "type_unspecified"
        platform_id               = "standard-v3"

        boot_disk {
            size = 64
            type = "network-hdd"
        }

        container_runtime {
            type = "containerd"
        }

        network_interface {
            ipv4               = true
            ipv6               = false
            nat                = true
            security_group_ids = [yandex_vpc_security_group.k8s-main-sg.id]
            subnet_ids         = [yandex_vpc_subnet.mysubnet-a.id, yandex_vpc_subnet.mysubnet-b.id, yandex_vpc_subnet.mysubnet-c.id]
        }

        resources {
            core_fraction = 20
            cores         = 2
            gpus          = 0
            memory        = 1
        }

        scheduling_policy {
            preemptible = false
        }
    }

    maintenance_policy {
        auto_repair  = false
        auto_upgrade = true
    }

    scale_policy {

        fixed_scale {
            size = 3
        }
    }
}

resource "null_resource" "connect-kubectl" { 
  provisioner "local-exec" {
   command = "yc managed-kubernetes cluster get-credentials --force ${yandex_kubernetes_cluster.k8s-regional.id} --external"
  }
}