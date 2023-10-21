variable "zone_id" {
  type        = string
  description = "DNS Zone"
  default = "dnsco48vufrpm7krn86i"
}

variable "name" {
  type        = string
  description = "DNS Name"
}

variable "data" {
  description = "IP"
}