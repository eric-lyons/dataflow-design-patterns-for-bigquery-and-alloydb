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


# module "instance_template" {
#   source     = "terraform-google-modules/vm/google//modules/instance_template"
#   version    = "7.9.0"
#   region     = var.region
#   project_id = var.project_id
#   subnetwork = local.subnet_name
#   service_account = {
#     email  = module.sa.email
#     scopes = ["https://www.googleapis.com/auth/cloud-platform"]
#   }
#   machine_type         = "e2-micro"
#   source_image_family  = "debian-11"
#   source_image_project = "debian-cloud"
#   disk_size_gb         = 10
#   name_prefix          = "alloydb-psql"
#   preemptible          = true
#   labels = {
#     label = "alloydb"
#   }
#   depends_on = [
#     module.sa,
#     google_service_account_iam_binding.sa_token_creator
#   ]
# }

module "simple-vm-example" {
  source     = "github.com/GoogleCloudPlatform/cloud-foundation-fabric/modules/compute-vm"
  project_id = var.project_id
  zone       = "${var.region}-b"
  name       = "alloydb"
  #service_account	= module.service-account-orch.iam_email
  service_account = local.deployment_service_account_name
  network_interfaces = [{
    network    = local.vpc_self_link
    subnetwork = local.subnet_self_link
  }]
}

module "iap_tunneling" {
  source                     = "terraform-google-modules/bastion-host/google//modules/iap-tunneling"
  version                    = "5.0.1"
  fw_name_allow_ssh_from_iap = "test-allow-ssh-from-iap-to-tunnel"
  project                    = var.project_id
  network                    = local.vpc_self_link
  service_accounts           = [local.deployment_service_account_name]
  instances = [{
    name = "alloydb"
    zone = "${var.region}-b"
  }]
  members = [
    "serviceAccount:${var.deployment_service_account_email}"
  ]
}

# Secret Manager
resource "google_secret_manager_secret" "alloy_secret" {
  project   = var.project_id
  secret_id = "alloy-db-secrets"
  labels = {
    label = "alloy"
  }
  replication {
    automatic = true
  }
}

resource "google_compute_global_address" "private_ip_address" {
  project       = var.project_id
  name          = "private-ip-address"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 24
  network       = local.vpc_self_link
}

# #create vpc connection
resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = local.vpc_self_link
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_address.name]
  depends_on              = [google_compute_global_address.private_ip_address]
}

resource "null_resource" "provision_alloydb" {
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<EOF
gcloud beta alloydb clusters create ${var.alloy["alloycluster"]} --password=${var.alloy["alloyclusterpassword"]} --network=${local.vpc_name} --region=${var.region} --project=${var.project_id}
gcloud beta alloydb instances create ${var.alloy["alloycluster"]} --instance-type=${var.alloy["alloyinstancetype"]} --cpu-count=${var.alloy["alloyinstancecpuecount"]} --region=${var.region} --cluster=${var.alloy["alloycluster"]} --project=${var.project_id}
EOF
  }
  depends_on = [google_service_networking_connection.private_vpc_connection]
}
