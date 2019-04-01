terraform {
  required_version = "<= 0.11.13"
}

locals {
  vpc_peer = "${var.enabled_vpc_peer == true ? 1 : 0}"
}

variable "enabled_vpc_peer" {
  type    = "string"
  default = true
}

variable "accepter_allow_remote_vpc_dns_resolution" {
  default = true
}

variable "requester_allow_remote_vpc_dns_resolution" {
  default = true
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
