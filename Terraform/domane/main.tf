##################### DNS Record ######################
resource "yandex_dns_recordset" "this" {
  zone_id = var.zone_id
  name    = var.name
  type    = "A"
  ttl     = 200
  data    = var.data
}