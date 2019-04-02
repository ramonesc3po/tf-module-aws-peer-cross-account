locals {
  name_requester_peer_side = "requester"
  name_requester_peer      = "${var.organization}-${local.name_vpc_peer}-${local.name_requester_peer_side}-${var.tier}"
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

variable "requester_allow_remote_vpc_dns_resolution" {
  default = true
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
  peer_vpc_id   = "${data.aws_vpc.accepter.id}"
  peer_owner_id = "${data.aws_caller_identity.accepter.account_id}"
  peer_region   = "${var.accepter_region}"
  auto_accept   = false
  vpc_id        = "${var.requester_vpc_id}"

  tags = "${merge(var.tags,
  map("Name", local.name_requester_peer),
  map("Tier", var.tier),
  map("Organization", var.tier),
  map("Side", local.name_requester_peer_side),
  map("Terraform", "true")
  )}"
}

resource "aws_vpc_peering_connection_options" "requester" {
  provider                  = "aws.requester"
  count                     = "${local.vpc_peer}"
  vpc_peering_connection_id = "${aws_vpc_peering_connection.requester.id}"

  requester {
    allow_remote_vpc_dns_resolution = "${var.requester_allow_remote_vpc_dns_resolution}"
  }
}

##
# Requester add route in route-table
##
locals {
  requester_route_tables_id    = "${distinct(data.aws_route_table.requester.*.route_table_id)}"
  requester_route_table_count  = "${length(local.requester_route_tables_id)}"
  requester_subnet_names       = "${distinct(sort(flatten(data.aws_subnet_ids.requester.*.ids)))}"
  requester_subnet_names_count = "${length(var.requester_subnet_names)}"
  local_requester_subnet_names_count = "${length(local.requester_subnet_names)}"
}

variable "requester_subnet_names" {
  type    = "list"
  default = []
}

data "aws_subnet_ids" "requester" {
  provider = "aws.requester"
  count    = "${local.vpc_peer && local.requester_subnet_names_count > 0 ? local.requester_subnet_names_count : 0}"
  vpc_id   = "${data.aws_vpc.requester.id}"

  filter {
    name   = "tag:Name"
    values = ["*${element(var.requester_subnet_names, count.index)}*"]
  }
}

data "aws_route_table" "requester" {
  provider  = "aws.requester"
  count     = "${local.vpc_peer && local.local_requester_subnet_names_count > 0 ? local.local_requester_subnet_names_count : 0}"
  vpc_id    = "${data.aws_vpc.requester.id}"
  subnet_id = "${element(local.requester_subnet_names, count.index)}"
}

resource "aws_route" "requester" {
  provider = "aws.requester"
  count                     = "${local.vpc_peer && local.requester_route_table_count > 0 ? local.requester_route_table_count : 0}"
  route_table_id            = "${element(local.requester_route_tables_id, count.index)}"
  destination_cidr_block    = "${data.aws_vpc.accepter.cidr_block}"
  vpc_peering_connection_id = "${aws_vpc_peering_connection.requester.id}"
}

