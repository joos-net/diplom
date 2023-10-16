###################### Network ######################
resource "yandex_vpc_network" "network-1" {
  name = "network1"
}
###################### NAT gateway and route table configuration ######################
resource "yandex_vpc_gateway" "nat-gateway" {
  name = "test-nat-gateway"
  shared_egress_gateway {}
}
resource "yandex_vpc_route_table" "route-table-nat" {
  name       = "route-table-nat"
  network_id = yandex_vpc_network.network-1.id
  static_route {
    destination_prefix = "0.0.0.0/0"
    gateway_id         = yandex_vpc_gateway.nat-gateway.id
  }
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
###################### Subnets ######################
resource "yandex_vpc_subnet" "internal-1" {
  name           = "internal-1"
  zone           = "ru-central1-a"
  v4_cidr_blocks = ["10.0.0.0/24"]
  network_id     = yandex_vpc_network.network-1.id
  route_table_id = yandex_vpc_route_table.route-table-nat.id
}
resource "yandex_vpc_subnet" "internal-2" {
  name           = "internal-2"
  zone           = "ru-central1-b"
  v4_cidr_blocks = ["192.168.10.0/24"]
  network_id     = yandex_vpc_network.network-1.id
  route_table_id = yandex_vpc_route_table.route-table-nat.id
}
resource "yandex_vpc_subnet" "external" {
  name           = "external"
  zone           = "ru-central1-b"
  v4_cidr_blocks = ["192.168.100.0/24"]
  network_id     = yandex_vpc_network.network-1.id
}
###################### Target group ######################
resource "yandex_alb_target_group" "web-target" {
  name           = "web-target"  
  target {
    subnet_id    = yandex_vpc_subnet.internal-1.id
    ip_address   = yandex_compute_instance_group.ig-1.instances[0].network_interface[0].ip_address
  }
  target {
    subnet_id    = yandex_vpc_subnet.internal-2.id
    ip_address   = yandex_compute_instance_group.ig-1.instances[1].network_interface[0].ip_address
  }
  target {
    subnet_id    = yandex_vpc_subnet.internal-2.id
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
  network_id         = yandex_vpc_network.network-1.id
  security_group_ids = [yandex_vpc_security_group.lb.id, yandex_vpc_security_group.self.id]

  allocation_policy {
    location {
      zone_id   = "ru-central1-b"
      subnet_id = yandex_vpc_subnet.internal-2.id
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
