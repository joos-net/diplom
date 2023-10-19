
###################### NAT group ######################
resource "yandex_vpc_security_group" "nat" {
  name       = "nat"
  description = "nat"
  network_id = yandex_vpc_network.network-1.id

  egress {
    protocol       = "ANY"
    description    = "Allow any to out"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}
###################### Self group ######################
resource "yandex_vpc_security_group" "self" {
  name        = "self"
  description = "in group"
  network_id  = yandex_vpc_network.network-1.id
  ingress {
    protocol          = "ANY"
    description       = "Allow incoming traffic from members of the same security group"
    from_port         = 0
    to_port           = 65535
    predefined_target = "self_security_group"
  }
  egress {
    protocol          = "ANY"
    description       = "Allow outgoing traffic to members of the same security group"
    from_port         = 0
    to_port           = 65535
    predefined_target = "self_security_group"
  }
}
###################### Load Balancer ######################
resource "yandex_vpc_security_group" "lb" {
  name        = "lb"
  description = "load balancer"
  network_id  = yandex_vpc_network.network-1.id
  ingress {
    description    = "Allow http"
    protocol       = "TCP"
    port           = "80"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description    = "Allow https"
    protocol       = "TCP"
    port           = "443"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description       = "healthchecks"
    protocol          = "TCP"
    port              = "30080"
    predefined_target = "loadbalancer_healthchecks"
  }
  egress {
    description    = "Allow any to out"
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}
###################### Bastion ######################
resource "yandex_vpc_security_group" "bastion" {
  name        = "bastion"
  description = "bastion sg"
  network_id  = yandex_vpc_network.network-1.id

  ingress {
    description    = "Allow SSH for bastion"
    protocol       = "TCP"
    port           = 22
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description    = "Allow any to out"
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}
###################### Zabbix - Kibana Web ######################
resource "yandex_vpc_security_group" "zabbix-kibana" {
  name        = "zabbix"
  description = "zabbix sg"
  network_id  = yandex_vpc_network.network-1.id

  ingress {
    description    = "Allow web for zabbix-web, kibana"
    protocol       = "TCP"
    port           = 80
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description    = "Allow ANY"
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}