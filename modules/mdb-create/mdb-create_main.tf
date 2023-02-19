terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
}

resource "yandex_mdb_mysql_cluster" "my-mysql" {
  name                = "my-mysql"
  environment         = "PRESTABLE"
  network_id          = var.yc_network_id
  version             = "8.0"
  security_group_ids  = [ yandex_vpc_security_group.mysql-sg.id ]
  deletion_protection = false

  resources {
    resource_preset_id = "s2.micro"
    disk_type_id       = "network-ssd"
    disk_size          = 20
  }

  host {
    zone      = "ru-central1-a"
    subnet_id = yandex_vpc_subnet.mydbsubnet.id
  }
}

resource "yandex_mdb_mysql_database" "db1" {
  cluster_id = yandex_mdb_mysql_cluster.my-mysql.id
  name       = var.yc_db_name
}

resource "yandex_mdb_mysql_user" "lab-user" {
  cluster_id = yandex_mdb_mysql_cluster.my-mysql.id
  name       = var.yc_db_user
  password   =  var.yc_db_password
  permission {
    database_name = yandex_mdb_mysql_database.db1.name
    roles         = ["ALL"]
  }
}

resource "yandex_vpc_security_group" "mysql-sg" {
  name       = "mysql-sg"
  network_id = var.yc_network_id

  ingress {
    description    = "MySQL"
    port           = 3306
    protocol       = "TCP"
    v4_cidr_blocks = [ "0.0.0.0/0" ]
  }
}

resource "yandex_vpc_subnet" "mydbsubnet" {
  name           = "my_db_subnet"
  zone           = "ru-central1-a"
  network_id     = var.yc_network_id
  v4_cidr_blocks = ["10.123.0.0/24"]
}