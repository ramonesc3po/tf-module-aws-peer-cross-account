locals {
  name_requester_peer_type = "requester"
  name_requester_vpc_peer  = "${var.organization}-${var.name_vpc_peer}-${local.name_requester_peer_type}-${var.tier}"
}

variable "requester_region" {
  description = ""
  type        = "string"
}

variable "requester_role_arn" {
  description = ""
  type        = "string"
}

variable "requester_role_session_name" {
  default = "vpc-peer"
}

variable "requester_external_id" {
  type    = "string"
  default = ""
}

variable "requester_vpc_id" {
  type = "string"
}

provider "aws" {
  alias   = "requester"
  version = ">= 1.25"

  region = "${var.requester_region}"

  assume_role {
    role_arn     = "${var.requester_role_arn}"
    session_name = "${var.requester_role_session_name}"
    external_id  = "${var.requester_external_id}"
  }
}

data "aws_vpc" "requester" {
  provider = "aws.requester"
  count    = "${local.vpc_peer}"
  id       = "${var.requester_vpc_id}"
}

data "aws_caller_identity" "requester" {
  provider = "aws.requester"
  count    = "${local.vpc_peer}"
}

resource "aws_vpc_peering_connection" "requester" {
  provider      = "aws.requester"
  count         = "${local.vpc_peer}"
  peer_vpc_id   = "${var.accepter_vpc_id}"
  peer_owner_id = "${data.aws_caller_identity.accepter.account_id}"
  peer_region   = "${var.accepter_region}"
  auto_accept   = "false"
  vpc_id        = "${var.requester_vpc_id}"

  requester {
    allow_remote_vpc_dns_resolution = "${var.requester_allow_remote_vpc_dns_resolution}"
  }

  tags = "${merge(var.tags,
  map("Name", local.name_requester_vpc_peer),
  map("Tier", var.tier),
  map("Peer", "requester"),
  map("Terraform", "true")
  )}"
}
