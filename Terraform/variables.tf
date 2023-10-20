###################### Servers names ######################
variable "name" {
  default = ["bastion", "zabbix-server", "zabbix-web", "elastic", "kibana"] #, "grafana", "prometheus"]
}
###################### Servers Memory ######################
variable "mem" {
  default = {
    "kibana"     = "8"
    "elastic"    = "8"
  }
}
###################### Servers cores ######################
variable "cores" {
  default = {
    "kibana"     = "4"
    "elastic"    = "4"
  }
}
###################### Servers image id #####################
variable "image_id" {
  default = "fd8clogg1kull9084s9o"
}
###################### Postgres variables ######################
variable "postgres_db" {
  default = "my_db"
}
variable "postgres_user" {
  default = "alice"
}
variable "postgres_pass" {
  default = "1234qwe1234"
}
###################### DNS ######################
variable "dns_id" {
  default = "dnsco48vufrpm7krn86i"
}
variable "my_domane" {
  default = "jo-os.ru."
}
variable "web_certificate" {
  default = "fpq86e0q4feikknb7bf5"
}
variable "zone_name" {
  default = "jo-os"
}
###################### Instance Group ######################
variable "account_id" {
  default = "ajeh9ejg8j4v3mjur30k"
}
variable "folder_id" {
  default = "b1ghauke2h8p27vt648a"
}
###################### Zabbix INFO ######################
variable "zabbix_user" {
  default = "Admin"
}
variable "zabbix_pass" {
  default = "zabbix"
}
###################### Elastic INFO ######################
variable "elastic_user" {
  default = "elastic"
}
variable "elastic_pass" {
  default = "DkIedPPSCbeje34i4"
}