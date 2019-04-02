locals {
  name_accepter_peer_side = "accepter"
  name_accepter_peer      = "${var.organization}-${var.name_vpc_peer}-${local.name_accepter_peer_side}-${var.tier}"
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

variable "accepter_allow_remote_vpc_dns_resolution" {
  default = true
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
  count    = "${local.vpc_peer}"
  id       = "${var.accepter_vpc_id}"
}

data "aws_caller_identity" "accepter" {
  provider = "aws.accepter"
  count    = "${local.vpc_peer}"
}

resource "aws_vpc_peering_connection_accepter" "accepter" {
  provider                  = "aws.accepter"
  count                     = "${local.vpc_peer}"
  vpc_peering_connection_id = "${aws_vpc_peering_connection.requester.id}"
  auto_accept               = true

  tags = "${merge(var.tags,
  map("Name", local.name_accepter_peer),
  map("Tier", var.tier),
  map("Organization", var.tier),
  map("Side", local.name_accepter_peer_side),
  map("Terraform", "true")
  )}"
}

resource "aws_vpc_peering_connection_options" "accepter" {
  provider                  = "aws.accepter"
  count                     = "${local.vpc_peer}"
  vpc_peering_connection_id = "${aws_vpc_peering_connection.requester.id}"

  accepter {
    allow_remote_vpc_dns_resolution = "${var.accepter_allow_remote_vpc_dns_resolution}"
  }
}

##
# Accepter add route in route-table
##
locals {
  route_tables_id    = "${distinct(data.aws_route_table.accepter.*.route_table_id)}"
  route_table_count  = "${length(local.route_tables_id)}"
  accepter_subnet_names       = "${distinct(sort(flatten(data.aws_subnet_ids.accepter.*.ids)))}"
  accepter_subnet_names_count = "${length(var.accepter_subnet_names)}"
  local_accepter_subnet_names_count = "${length(local.accepter_subnet_names)}"
}

variable "accepter_subnet_names" {
  type    = "list"
  default = []
}

data "aws_subnet_ids" "accepter" {
  provider = "aws.accepter"
  count    = "${local.vpc_peer && local.accepter_subnet_names_count > 0 ? local.accepter_subnet_names_count : 0}"
  vpc_id   = "${data.aws_vpc.accepter.id}"

  filter {
    name   = "tag:Name"
    values = ["*${element(var.accepter_subnet_names, count.index)}*"]
  }
}

data "aws_route_table" "accepter" {
  provider  = "aws.accepter"
  count     = "${local.vpc_peer && local.local_accepter_subnet_names_count > 0 ? local.local_accepter_subnet_names_count : 0}"
  vpc_id    = "${data.aws_vpc.accepter.id}"
  subnet_id = "${element(local.accepter_subnet_names, count.index)}"
}

resource "aws_route" "accepter" {
  provider = "aws.accepter"
  count                     = "${local.vpc_peer && local.route_table_count > 0 ? local.route_table_count : 0}"
  route_table_id            = "${element(local.route_tables_id, count.index)}"
  destination_cidr_block    = "${data.aws_vpc.accepter.cidr_block}"
  vpc_peering_connection_id = "${aws_vpc_peering_connection.requester.id}"
}
