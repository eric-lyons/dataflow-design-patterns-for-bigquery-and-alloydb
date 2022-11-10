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

# tfdoc:file:description Terraform Variables.

####################################################################################
# Variables (Set in the ../terraform.tfvars.json file) or passed viw command line
####################################################################################

# CONDITIONS: (Only If) the project_number is NOT provided and Terraform will be creating the GCP project for you
variable "billing_account_id" {
  type        = string
  description = "Billing account id."
  validation {
    condition     = length(var.billing_account_id) > 0
    error_message = "The billing_acount_id is required."
  }
}

variable "org_id" {
  description = "The organization ID.	"
  type        = string
  validation {
    condition     = length(var.org_id) > 0
    error_message = "The org_id is required."
  }
}

# CONDITIONS: (Always Required)
variable "project_id" {
  type        = string
  description = "The GCP Project Id/Name or the Prefix of a name to generate (e.g. data-analytics-demo-xxxxxxxxxx)."
  validation {
    condition     = length(var.project_id) > 0
    error_message = "The project_id is required."
  }
}

variable "gcp_account_name" {
  type        = string
  description = "This is the name of the user who is deploying the IaC.  It is used to set security items. (e.g. admin@mydomain.com)"
  validation {
    condition     = length(var.gcp_account_name) > 0
    error_message = "The GCP Account Name is required."
  }
}