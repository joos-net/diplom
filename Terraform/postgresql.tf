
###################### Postgresql Cluster ######################
resource "yandex_mdb_postgresql_cluster" "postgres" {
  name               = "postgres"
  environment        = "PRESTABLE"
  network_id         = module.net.vpc_id
  security_group_ids = [module.sg-self.id]

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
    subnet_id = module.net.private_subnets["10.0.0.0/24"].subnet_id
  }

  host {
    zone      = "ru-central1-b"
    subnet_id = module.net.private_subnets["192.168.10.0/24"].subnet_id
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