module "vpc-peer-cross-account-example" {
  source = "../"

  # Requester vpc peer
  requester_region            = "us-east-1"
  requester_role_arn          = ""
  requester_role_session_name = ""
  requester_external_id       = ""
  requester_vpc_id = ""
  route_table_id = [""]

  # Accepter vpc peer
  accepter_region            = ""
  accepter_role_arn          = ""
  accepter_role_session_name = ""
  accepter_external_id       = ""
  accepter_vpc_id  = ""

  # Usage in both
  name_vpc_peer = "api_rds"
  tier          = "production"
  organization  = "zigzaga"
}

