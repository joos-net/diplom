###################### Network - Subnets ######################
module "net" {
  source              = "./yc-vpc"
  labels              = { tag = "example" }
  network_description = "terraform-created"
  network_name        = "network-1"
  create_vpc          = true
  public_subnets = [
    {
      "v4_cidr_blocks" : ["192.168.100.0/24"],
      "zone" : "ru-central1-b"
    }
  ]
  private_subnets = [
    {
      "v4_cidr_blocks" : ["10.0.0.0/24"],
      "zone" : "ru-central1-a"
    },
    {
      "v4_cidr_blocks" : ["192.168.10.0/24"],
      "zone" : "ru-central1-b"
    }
  ]
}
###################### Static IP ######################
resource "yandex_vpc_address" "static" {
  name                = "static"
  deletion_protection = "false"
  external_ipv4_address {
    zone_id = "ru-central1-b"
  }
}
###################### A DNS Record ######################
resource "yandex_dns_recordset" "rs1" {
  zone_id = var.dns_id
  name    = var.my_domane
  type    = "A"
  ttl     = 200
  data    = [yandex_vpc_address.static.external_ipv4_address[0].address]
}
###################### Target group ######################
resource "yandex_alb_target_group" "web-target" {
  name           = "web-target"  
  target {
    subnet_id    = module.net.private_subnets["10.0.0.0/24"].subnet_id
    ip_address   = yandex_compute_instance_group.ig-1.instances[0].network_interface[0].ip_address
  }
  target {
    subnet_id    = module.net.private_subnets["192.168.10.0/24"].subnet_id
    ip_address   = yandex_compute_instance_group.ig-1.instances[1].network_interface[0].ip_address
  }
  target {
    subnet_id    = module.net.private_subnets["192.168.10.0/24"].subnet_id
    ip_address   = yandex_compute_instance_group.ig-1.instances[2].network_interface[0].ip_address
  }
}
###################### Backend group ######################
resource "yandex_alb_backend_group" "web-backend" {
  name = "web-backend"
  session_affinity {
    connection {
      source_ip = false
    }
  }

  http_backend {
    name             = "my-web-backend"
    weight           = 1
    port             = 80
    target_group_ids = [yandex_alb_target_group.web-target.id]
    load_balancing_config {
      panic_threshold = 90
    }
    healthcheck {
      timeout             = "10s"
      interval            = "2s"
      healthy_threshold   = 10
      unhealthy_threshold = 15
      http_healthcheck {
        path = "/"
      }
    }
  }
}
###################### HTTP-router ######################
resource "yandex_alb_http_router" "web-router" {
  name = "web-router"
  labels = {
    tf-label    = "tf-label-value"
    empty-label = ""
  }
}

resource "yandex_alb_virtual_host" "my-virtual-host" {
  name           = "web-virt"
  http_router_id = yandex_alb_http_router.web-router.id
  route {
    name = "web-route"
    http_route {
      http_route_action {
        backend_group_id = yandex_alb_backend_group.web-backend.id
        timeout          = "60s"
      }
    }
  }
}
###################### Load balancer ######################
resource "yandex_alb_load_balancer" "web-balancer" {
  name               = "web-balancer"
  network_id         = module.net.vpc_id
  security_group_ids = [module.sg-lb.id, module.sg-self.id]

  allocation_policy {
    location {
      zone_id   = "ru-central1-b"
      subnet_id = module.net.private_subnets["192.168.10.0/24"].subnet_id
    }
  }

  listener {
    name = "listener-https"
    endpoint {
      address {
        external_ipv4_address {
          address = yandex_vpc_address.static.external_ipv4_address[0].address
        }
      }
      ports = [443]
    }
    tls {
      default_handler {
        http_handler {
          http_router_id = yandex_alb_http_router.web-router.id
        }
        certificate_ids = [var.web_certificate]
      }
    }
  }
}
