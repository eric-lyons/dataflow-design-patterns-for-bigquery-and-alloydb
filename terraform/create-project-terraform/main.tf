####################################################################################
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
####################################################################################

####################################################################################
# README
# This is the main entry point into the Terraform creation script
# This script can be run in a different ways:

# Author: John DeMartino
#
# References:
# Terraform for Google: https://registry.terraform.io/providers/hashicorp/google/latest/docs
#                       https://www.terraform.io/language/resources/provisioners/local-exec

####################################################################################
# Local Variables 
####################################################################################
locals {
  # IAM Permissions for orch-sa-cmp 
  sa_deployment_iam_permissions = toset(
    ["roles/bigquery.dataOwner",
      "roles/compute.networkAdmin",
      "roles/compute.securityAdmin",
      "roles/secretmanager.admin",
      "roles/iam.securityAdmin",
      "roles/iam.serviceAccountAdmin",
      "roles/storage.admin",
      "roles/iam.serviceAccountUser",
      "roles/dataflow.admin",
      "roles/compute.admin"
    ]
  )
}
####################################################################################
# Reuseable Modules
####################################################################################
module "project_factory" {
  source            = "terraform-google-modules/project-factory/google"
  version           = "13.1.0"
  org_id            = var.org_id
  billing_account   = var.billing_account_id
  random_project_id = true
  name              = var.project_id
  labels            = { "looker" : "looker" }
}

# # Activate API services
module "project_services" {
  source                      = "terraform-google-modules/project-factory/google//modules/project_services"
  version                     = "14.0.0"
  project_id                  = module.project_factory.project_id
  enable_apis                 = true
  disable_services_on_destroy = true
  # add alloydb 
  # add dataflow
  activate_apis = [
    "artifactregistry.googleapis.com",
    "bigquery.googleapis.com",
    "bigqueryreservation.googleapis.com",
    "bigquerystorage.googleapis.com",
    "cloudbuild.googleapis.com",
    "cloudkms.googleapis.com",
    "compute.googleapis.com",
    "container.googleapis.com",
    "containerregistry.googleapis.com",
    "pubsub.googleapis.com",
    "servicenetworking.googleapis.com",
    "storage.googleapis.com",
    "storage-component.googleapis.com",
    "secretmanager.googleapis.com",
    "iap.googleapis.com",
    "dataflow.googleapis.com",
    "alloydb.googleapis.com"

  ]
}

resource "google_project_iam_member" "sa_deployment_iam_permissions" {
  for_each = local.sa_deployment_iam_permissions
  project  = module.project_factory.project_id
  role     = each.key
  member   = "serviceAccount:${module.project_factory.service_account_email}"
  depends_on = [
    module.project_factory
  ]
}

resource "google_service_account_iam_binding" "composer_sa_deployment_iam_permissions_token_creator" {
  service_account_id = "projects/${module.project_factory.project_id}/serviceAccounts/${module.project_factory.service_account_email}"
  role               = "roles/iam.serviceAccountTokenCreator"
  members            = ["user:${var.gcp_account_name}"]
  depends_on = [
    google_project_iam_member.sa_deployment_iam_permissions
  ]
}

module "gcs_buckets" {
  source  = "terraform-google-modules/cloud-storage/google//modules/simple_bucket"
  version = "3.4.0"
  project_id  = module.project_factory.project_id
  name = "remote-backend-${module.project_factory.project_id}"
  location = "US"
  versioning = true

}