# Copyright 2022 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# terraform {
#   required_version = ">= 1.3.1"
#   required_providers {
#     google = {
#       source  = "hashicorp/google"
#       version = ">= 4.40.0" # tftest
#     }
#     google-beta = {
#       source  = "hashicorp/google-beta"
#       version = ">= 4.40.0" # tftest
#     }
#   }
# }


terraform {
  required_version = ">= 0.13"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 3.43, < 5.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = ">= 3.43, < 5.0"
    }
  }
  provider_meta "google" {
    module_name = "blueprints/terraform/terraform-google-project-factory:project_services/v13.1.0"
  }

}

locals {
  deployment_service_account_name = var.deployment_service_account_email
}

provider "google" {
  alias   = "impersonation"
  project = var.project_id
  scopes = [
    "https://www.googleapis.com/auth/cloud-platform",
    "https://www.googleapis.com/auth/userinfo.email",
  ]
}

data "google_service_account_access_token" "default" {
  provider               = google.impersonation
  target_service_account = local.deployment_service_account_name
  scopes                 = ["userinfo-email", "cloud-platform"]
  lifetime               = "3600s"
}

provider "google" {
  project         = var.project_id
  access_token    = data.google_service_account_access_token.default.access_token
  request_timeout = "3600s"
}


provider "google-beta" {
  project         = var.project_id
  access_token    = data.google_service_account_access_token.default.access_token
  request_timeout = "3600s"
}
