###################### locals Security Group ######################
locals {
  self_sg = yandex_vpc_security_group.self.id
  nat_sg = yandex_vpc_security_group.nat.id
  kibana_sg = yandex_vpc_security_group.kibana.id
  bastion_sg = yandex_vpc_security_group.bastion.id
  zabbix_sg = yandex_vpc_security_group.zabbix.id
}

################### Create VM #####################
resource "yandex_compute_instance" "vm" {
  for_each    = toset(var.name)
  name        = each.key
  hostname    = each.key
  platform_id = "standard-v3"
  zone        = each.key == "web2" ? "ru-central1-a" : "ru-central1-b"
  labels = {
    ansible_groups = each.key
  }
  resources {
    core_fraction = 20
    cores         = lookup(var.cores, each.key, "2")
    memory        = lookup(var.mem, each.key, "2")
  }
  boot_disk {
    initialize_params {
      image_id = var.image_id
      size     = each.key == "elastic" ? 30 : 15
    }
  }
  network_interface {
    subnet_id          = each.key == "kibana" || each.key == "zabbix-web" || each.key == "bastion" ? yandex_vpc_subnet.external.id : yandex_vpc_subnet.internal-2.id
    nat                = each.key == "kibana" || each.key == "zabbix-web" || each.key == "bastion" ? true : false
    security_group_ids = each.key == "bastion" ? [local.bastion_sg, local.self_sg] : each.key == "kibana" ? [local.kibana_sg, local.self_sg] : each.key == "zabbix-web" ? [local.zabbix_sg, local.self_sg] : [local.self_sg, local.nat_sg]
  }
  metadata = {
    user-data = "${file("./meta.yml")}"
  }
  scheduling_policy {
    preemptible = true
  }
}
################### Create Instance Group ######################
resource "yandex_compute_instance_group" "ig-1" {
  name               = "fixed-ig"
  folder_id          = var.folder_id
  service_account_id = var.account_id
  instance_template {
    name        = "web{instance.index}"
    hostname    = "web{instance.index}"
    platform_id = "standard-v3"

    resources {
      core_fraction = 20
      memory        = 2
      cores         = 2
    }
    boot_disk {
      mode = "READ_WRITE"
      initialize_params {
        image_id = var.image_id
        size = 15
      }
    }
    network_interface {
      network_id = yandex_vpc_network.network-1.id
      subnet_ids = [ yandex_vpc_subnet.internal-1.id, yandex_vpc_subnet.internal-2.id]
      security_group_ids = [local.self_sg, local.nat_sg]
    }

    metadata = {
      user-data = file("./meta.yml")
    }
  }

  scale_policy {
    fixed_scale {
      size = 3
    }
  }

  allocation_policy {
    zones = ["ru-central1-a", "ru-central1-b"]
  }

  deploy_policy {
    max_unavailable = 1
    max_expansion   = 0
  }

  load_balancer {
    target_group_name        = "target-group"
    target_group_description = "load balancer target group"
  }
}
################### Postgres DB ID for Ansible ######################
resource "local_file" "private_key" {
  content  = yandex_mdb_postgresql_cluster.postgres.host[0].fqdn
  filename = pathexpand("~/Desktop/very_secure_dir/postgresql_id.txt")
}
################### Create hosts Ansible ######################
resource "local_file" "hosts" {
  filename = pathexpand("~/dip-zabb/Ansible/hosts")
  content  = <<-EOT
    %{for server in yandex_compute_instance.vm}
    [${server.hostname}]
    ${server.network_interface[0].ip_address}
    %{endfor}
    %{for web in yandex_compute_instance_group.ig-1.instances[*]}
    [${web.name}]
    ${web.network_interface[0].ip_address}
    %{endfor}
  EOT
}
################### Create SSH config ######################
resource "local_file" "config" {
  filename = pathexpand("~/.ssh/config")
  content  = <<-EOT
      %{for server in yandex_compute_instance.vm}
      %{if server.hostname == "bastion"}
      Host bastion
        User joos
        Hostname ${server.network_interface.0.nat_ip_address}
        StrictHostKeyChecking no
      %{endif}
      %{endfor~}

      %{for server in yandex_compute_instance.vm}
      Host ${server.network_interface.0.ip_address}
        ProxyJump bastion
        StrictHostKeyChecking no
      %{endfor~}
      %{for web in yandex_compute_instance_group.ig-1.instances[*]}
      Host ${web.network_interface.0.ip_address}
        ProxyJump bastion
        StrictHostKeyChecking no
      %{endfor~}
  EOT
}
################### Create README ######################
resource "local_file" "readme" {
  filename = pathexpand("~/dip-zabb/README.md")
  content  = <<-EOT
   Zabbix+
   
   Zabbix:
   - Zabbix Server IP - ${yandex_compute_instance.vm["zabbix-web"].network_interface.0.nat_ip_address}
   - Zabbix User - ${var.zabbix_user}
   - Zabbix Passwort - ${var.zabbix_pass}

   Kibana:
   - Kibana Server IP - ${yandex_compute_instance.vm["kibana"].network_interface.0.nat_ip_address}
   - Kibana User - ${var.elastic_user}
   - Kibana Passwort - ${var.elastic_pass}

   Web:
   - Website - https://jo-os.ru
   - Website IP - ${yandex_vpc_address.static.external_ipv4_address[0].address}
  EOT
}