###################### NAT group ######################
module "sg-nat" {
  source     = "./yc-sg"
  name       = "nat"
  network_id = module.net.vpc_id
  ingress_rules_with_cidrs = []
  ingress_rules_with_sg_ids = []
  egress_rules = [
    {
      protocol       = "ANY"
      description    = "To the internet"
      v4_cidr_blocks = ["0.0.0.0/0"]
    },
  ]
}
###################### Self group ######################
module "sg-self" {
  source     = "./yc-sg"
  name       = "self"
  network_id = module.net.vpc_id
  self     = true
  ingress_rules_with_cidrs = [
    {
        protocol          = "ANY"
        description       = "Allow incoming traffic from members of the same security group"
        from_port         = 0
        to_port           = 65535
        v4_cidr_blocks    = ["10.0.0.0/24","192.168.10.0/24","192.168.10.0/24"]
    },
  ]
  ingress_rules_with_sg_ids = []
  egress_rules = [
    {
        protocol          = "ANY"
        description       = "Allow incoming traffic from members of the same security group"
        from_port         = 0
        to_port           = 65535
    },
  ]
}
###################### Load Balancer ######################
module "sg-lb" {
  source     = "./yc-sg"
  name       = "lb"
  network_id = module.net.vpc_id
  nlb_hc     = true
  ingress_rules_with_cidrs = [
    {
      description    = "https"
      port           = 443
      protocol       = "ANY"
      v4_cidr_blocks = ["0.0.0.0/0"]
    },
    {
      description       = "healthchecks"
      protocol          = "TCP"
      port              = "30080"
      predefined_target = "loadbalancer_healthchecks"
      v4_cidr_blocks    = ["0.0.0.0/0"]
    },
  ]
  ingress_rules_with_sg_ids = []
  egress_rules = [
    {
      protocol       = "ANY"
      description    = "To the internet"
      v4_cidr_blocks = ["0.0.0.0/0"]
    },
  ]
}
###################### Bastion ######################
module "sg-bastion" {
  source     = "./yc-sg"
  name       = "bastion"
  network_id = module.net.vpc_id
  ingress_rules_with_cidrs = [
    {
      description    = "ssh-bastion"
      port           = 22
      protocol       = "ANY"
      v4_cidr_blocks = ["0.0.0.0/0"]
    },
  ]
  ingress_rules_with_sg_ids = []
  egress_rules = [
    {
      protocol       = "ANY"
      description    = "To the internet"
      v4_cidr_blocks = ["0.0.0.0/0"]
    },
  ]
}
###################### Zabbix - Kibana Web ######################
module "sg-zabb-kib" {
  source     = "./yc-sg"
  name       = "zabbix-kibana"
  network_id = module.net.vpc_id
  ingress_rules_with_cidrs = [
    {
      description    = "Allow web for zabbix-web, kibana"
      port           = 80
      protocol       = "ANY"
      v4_cidr_blocks = ["0.0.0.0/0"]
    },
  ]
  ingress_rules_with_sg_ids = []
  egress_rules = [
    {
      protocol       = "ANY"
      description    = "To the internet"
      v4_cidr_blocks = ["0.0.0.0/0"]
    },
  ]
}