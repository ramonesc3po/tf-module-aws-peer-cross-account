terraform {
  required_version = "<= 0.11.13"
}

locals {
  vpc_peer      = "${var.enabled_vpc_peer == true ? 1 : 0}"
  name_vpc_peer = "${var.name_vpc_peer}"
}

variable "enabled_vpc_peer" {
  default = "true"
}

variable "name_vpc_peer" {
  type = "string"
}

variable "organization" {
  type    = "string"
  default = ""
}

variable "tier" {
  type = "string"
}

variable "tags" {
  type    = "map"
  default = {}
}
