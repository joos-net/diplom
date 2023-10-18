
###################### Postgresql Cluster ######################
resource "yandex_mdb_postgresql_cluster" "postgres" {
  name               = "postgres"
  environment        = "PRESTABLE"
  network_id         = yandex_vpc_network.network-1.id
  security_group_ids = [yandex_vpc_security_group.self.id]

  config {
    version      = 14
    autofailover = true
    resources {
      resource_preset_id = "c3-c2-m4"
      disk_type_id       = "network-ssd"
      disk_size          = 16
    }
  }

  maintenance_window {
    type = "ANYTIME"
  }

  host {
    zone      = "ru-central1-a"
    subnet_id = yandex_vpc_subnet.internal-1.id
  }

  host {
    zone      = "ru-central1-b"
    subnet_id = yandex_vpc_subnet.internal-2.id
  }
}
###################### Creare DB User ######################
resource "yandex_mdb_postgresql_user" "postgres_user" {
  cluster_id = yandex_mdb_postgresql_cluster.postgres.id
  name       = var.postgres_user
  password   = var.postgres_pass
}
##################### Create DB ######################
resource "yandex_mdb_postgresql_database" "db" {
  cluster_id = yandex_mdb_postgresql_cluster.postgres.id
  name       = var.postgres_db
  owner      = yandex_mdb_postgresql_user.postgres_user.name
}