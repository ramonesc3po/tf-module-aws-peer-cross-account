locals {
  name_accepter_peer_type = "accepter"
  name_accepter_vpc_peer  = "${var.organization}-${var.name_vpc_peer}-${local.name_accepter_peer_type}-${var.tier}"
}

variable "accepter_region" {
  description = ""
  type        = "string"
}

variable "accepter_role_arn" {
  description = ""
  type        = "string"
}

variable "accepter_role_session_name" {
  default = "vpc-peer"
}

variable "accepter_external_id" {
  type    = "string"
  default = ""
}

variable "accepter_vpc_id" {
  type = "string"
}

provider "aws" {
  alias   = "accepter"
  version = ">= 1.25"

  region = "${var.accepter_region}"

  assume_role {
    role_arn     = "${var.accepter_role_arn}"
    session_name = "${var.accepter_role_session_name}"
    external_id  = "${var.accepter_external_id}"
  }
}

data "aws_vpc" "accepter" {
  provider = "aws.accepter"
  count    = "${local.vpc_peer == true}"
}

data "aws_caller_identity" "accepter" {
  provider = "aws.accepter"
  count    = "${local.vpc_peer == true}"
}

resource "aws_vpc_peering_connection_accepter" "accepter" {
  provider                  = "aws.accepter"
  count                     = "${local.vpc_peer == true}"
  vpc_peering_connection_id = "${aws_vpc_peering_connection.requester.id}"
  auto_accept               = true

  accepter {
    allow_remote_vpc_dns_resolution = "${var.requester_allow_remote_vpc_dns_resolution}"
  }

  tags = "${merge(var.tags,
  map("Name", local.name_accepter_vpc_peer),
  map("Tier", var.tier),
  map("Peer", local.name_accepter_peer_type),
  map("Terrafor", "true")
  )}"
}
