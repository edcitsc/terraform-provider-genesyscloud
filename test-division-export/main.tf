terraform {
  required_providers {
    genesyscloud = {
      source = "mypurecloud/genesyscloud"
    }
  }
}

provider "genesyscloud" {
  # Provider will use environment variables if set:
  # GENESYSCLOUD_OAUTHCLIENT_ID
  # GENESYSCLOUD_OAUTHCLIENT_SECRET  
  # GENESYSCLOUD_REGION (or GENESYSCLOUD_AWS_REGION)
  #
  # Or you can set them explicitly:
  # oauthclient_id     = ""
  # oauthclient_secret = ""
  # aws_region         = "us-east-1"
}

# Test 1: Export a single division WITHOUT dependency resolution
resource "genesyscloud_tf_export" "test_division_no_deps" {
  directory                    = "./export_division_no_deps"
  include_filter_resources     = ["genesyscloud_auth_division"]
  include_state_file           = false
  export_format                = "json"
  enable_dependency_resolution = false
  log_permission_errors        = true
}

# Test 2: Export a single division WITH dependency resolution
resource "genesyscloud_tf_export" "test_division_with_deps" {
  directory                    = "./export_division_with_deps"
  include_filter_resources     = ["genesyscloud_auth_division"]
  include_state_file           = false
  export_format                = "json"
  enable_dependency_resolution = true
  log_permission_errors        = true
}

# Test 3: Export a SPECIFIC division by ID with dependency resolution
resource "genesyscloud_tf_export" "test_specific_division" {
  directory                      = "./export_specific_division"
  include_filter_resources_by_id = ["genesyscloud_auth_division::YOUR-DIVISION-GUID-HERE"]
  include_state_file             = false
  export_format                  = "json"
  enable_dependency_resolution   = true
  log_permission_errors          = true
}

output "export1_location" {
  value = "Export without deps: ${genesyscloud_tf_export.test_division_no_deps.directory}"
}

output "export2_location" {
  value = "Export with deps: ${genesyscloud_tf_export.test_division_with_deps.directory}"
}

output "export3_location" {
  value = "Export specific division: ${genesyscloud_tf_export.test_specific_division.directory}"
}
