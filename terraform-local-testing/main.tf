terraform {
  required_version = ">= 1.0.0"
  required_providers {
    genesyscloud = {
      source  = "mypurecloud/genesyscloud"
      version = ">= 1.6.0"
    }
  }
}

provider "genesyscloud" {
  oauthclient_id     = "insert_client_ID_Here"
  oauthclient_secret = "insert_Secret_Here"
  aws_region         = "region" # Change to your region (e.g., us-east-1, eu-west-1, ap-southeast-2)
}

# Add your Genesys Cloud resources here
# For example:
# resource "genesyscloud_user" "example" {
#   email = "user@example.com"
#   name  = "John Doe"
# }
