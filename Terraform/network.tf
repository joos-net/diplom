###################### Network - Subnets ######################
module "net" {
  source              = "./yc-vpc"
  labels              = { tag = "my-net" }
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
###################### A DNS Record ######################
module "zabbix_dns" {
  source = "./domain"
  name = "zabbix"
  data = [yandex_compute_instance.vm["zabbix-web"].network_interface.0.nat_ip_address]
}
module "kibana_dns" {
  source = "./domain"
  name = "kibana"
  data = [yandex_compute_instance.vm["kibana"].network_interface.0.nat_ip_address]
}
###################### Load balancer ######################
module "alb" {
  source               = "./yc-alb"
  network_id           = module.net.vpc_id
  public_dns_zone_id   = var.dns_id
  public_dns_zone_name = var.zone_name
  security_groups_ids_list = [ module.sg-lb.id, module.sg-self.id  ] 

  alb_load_balancer = {
    name = "alb-test"
###################### Target group ######################
    alb_target_groups = {
      "target-group-a" = {
        targets = [
          {
            subnet_id  = module.net.private_subnets["10.0.0.0/24"].subnet_id
            ip_address = yandex_compute_instance_group.ig-1.instances[0].network_interface[0].ip_address
          },
          {
            subnet_id  = module.net.private_subnets["192.168.10.0/24"].subnet_id
            ip_address = yandex_compute_instance_group.ig-1.instances[1].network_interface[0].ip_address
          },
          {
            subnet_id  = module.net.private_subnets["192.168.10.0/24"].subnet_id
            ip_address = yandex_compute_instance_group.ig-1.instances[2].network_interface[0].ip_address
          },
        ]
      }
    }
###################### Backend group ######################
    alb_backend_groups = {
      "test-bg-a" = {
        http_backends = [
          {
            name   = "test-backend-a"
            port   = 80
            weight = 1
            healthcheck = {
              healthcheck_port = 80
              http_healthcheck = {
              path = "/"
              http2 = "false"
              }
            }
            http2 = "false"
            target_groups_names_list = ["target-group-a"]
          }
        ]
      }
    }
###################### HTTP-router ######################
    alb_http_routers = ["http-router-test"]

    alb_virtual_hosts = {
      "virtual-host-a" = {
        http_router_name = "http-router-test"
        #authority        = ["jo-os.ru"]
        route = {
          name = "http-virtual-route-a"
          http_route = {
            http_route_action = {
              backend_group_name = "test-bg-a"
            }
          }
        }
      }
    }

    // ALB locations
    alb_locations = [
      {
        zone      = "ru-central1-b"
        subnet_id = module.net.private_subnets["192.168.10.0/24"].subnet_id
      }
    ]

    alb_listeners = [
      {
        name = "test-listener-http"
        endpoint = {
          address = {
            external_ipv4_address = {}
          }
          ports = ["443"]
        }
        tls = {
          default_handler = {
            http_handler = {
              http_router_name = "http-router-test"
            }
          certificate_ids = [var.web_certificate]
          }
        }
      }
    ]

    log_options = {
      disable = true
    }
  }
}