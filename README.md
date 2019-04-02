Terraform Module AWS Peer Cross Account
======================================
This module create one vpc-peer in aws cross account. If you would usage in same account this module is not for you.

Example
---------
```hcl-terraform
module "vpc-peer-cross-account-example" {
  source = "."

  # Requester vpc peer
  requester_region            = ""
  requester_role_arn          = ""
  requester_role_session_name = ""
  requester_external_id       = ""
  requester_vpc_id = ""
  requester_subnet_names = [""]

  # Accepter vpc peer
  accepter_region            = ""
  accepter_role_arn          = ""
  accepter_role_session_name = ""
  accepter_external_id       = ""
  accepter_vpc_id  = ""
  accepter_subnet_names = [""]


  # Usage in both
  name_vpc_peer = "api_rds"
  tier          = "production"
  organization  = "zigzaga"
}
```
Author
------
Ramones C3po
