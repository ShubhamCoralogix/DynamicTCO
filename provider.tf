terraform {
  required_providers {
    coralogix = {
      source  = "coralogix/coralogix"
      version = "~> 3.0"
    }
  }
}

# Region: AP1 (India) -> coralogix.in
provider "coralogix" {
  api_key = var.coralogix_api_key
  env     = "ap1"
}