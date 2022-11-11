# Action Items:
# Add module to add VM within the VPC for psql client
# Add firewall rules to allow psql and ssh access to the VPC
# Add compute engine start up script to install psql client
# refactor resources to use modules

# project create project and bucket
# resources to deploy 
# creating the database


# Service account impersonation is detailed here: https://medium.com/google-cloud/a-hitchhikers-guide-to-gcp-service-account-impersonation-in-terraform-af98853ebd37
# terraform information on serviec accounts is listed here: https://medium.com/google-cloud/a-hitchhikers-guide-to-gcp-service-account-impersonation-in-terraform-af98853ebd37

locals {
  # IAM Permissions
  sa_iam_permissions = toset(
    ["roles/bigquery.dataEditor",
      "roles/bigquery.jobUser",
      "roles/bigquery.dataViewer",
      "roles/bigquery.admin",
      "roles/bigquery.user",
      "roles/logging.admin",
      "roles/logging.logWriter",
      "roles/monitoring.metricWriter",
      "roles/dataflow.admin",
      "roles/dataflow.worker",
      "roles/dataflow.developer",
      "roles/compute.viewer",   
      "roles/compute.networkUser",
      "roles/storage.objectAdmin",
      "roles/composer.ServiceAgentV2Ext",
      "roles/storage.objectViewer",
      "roles/secretmanager.secretAccessor"
    ]
  )
  use_shared_vpc     = var.network_config != null
  shared_vpc_project = try(var.network_config.host_project, "")

  subnet_self_link = (
    local.use_shared_vpc
    ? var.network_config.subnet_self_links.subnet_self_link
    : module.vpc.0.subnets_self_links[0]
  )

  vpc_self_link = (
    local.use_shared_vpc
    ? var.network_config.network_self_link
    : module.vpc.0.network_self_link
  )

  subnet_name = (
    local.use_shared_vpc
    ? var.network_config.subnet_self_links.subnet_name
    : module.vpc.0.subnets_names[0]
  )

  vpc_name = (
    local.use_shared_vpc
    ? var.network_config.network_name
    : module.vpc.0.network_name
  )
}

####################################################################################
#Modules
####################################################################################
# Create service account for workload
module "sa" {
  source       = "terraform-google-modules/service-accounts/google"
  version      = "4.1.1"
  project_id   = var.project_id
  names        = ["alloydb"]
  display_name = "Data platform Orchestration service account"
}

resource "google_service_account_iam_binding" "sa_token_creator" {
  service_account_id = "projects/${var.project_id}/serviceAccounts/${module.sa.email}"
  role               = "roles/iam.serviceAccountTokenCreator"
  members            = ["serviceAccount:${var.deployment_service_account_email}"]
}

resource "google_project_iam_member" "sa_iam" {
  for_each = local.sa_iam_permissions
  project  = var.project_id
  role     = each.key
  member   = module.sa.iam_email
  depends_on = [
    module.sa
  ]
}

module "vpc" {
 count      = local.use_shared_vpc ? 0 : 1
 source  = "terraform-google-modules/network/google"
 version = "5.2.0"
 project_id   = var.project_id
 network_name = var.vpcname
 mtu          = 1460

  subnets = [
    {
      subnet_ip =         var.vpc_subnet_range
      subnet_name          = "subnet"
      subnet_region        = var.region
      subnet_private_access = "true"
      subnet_flow_logs      = "true"
    }
  ]
}

module "vpc_firewall" {
  source       = "terraform-google-modules/network/google//modules/firewall-rules"
  version      = "5.2.0"
  count        = local.use_shared_vpc ? 0 : 1
  project_id   = var.project_id
  network_name = module.vpc.0.network_name
  rules = [{
    name                    = "alloydb-ingress-admin"
    description             = "Access from the admin subnet to all subnets"
    direction               = "INGRESS"
    priority                = null
    ranges                  = [var.vpc_subnet_range]
    source_tags             = null
    source_service_accounts = null
    target_tags             = null
    target_service_accounts = null
    allow = [{
      protocol = "all"
      ports    = null
    }]
    deny = []
    log_config = {
      metadata = "INCLUDE_ALL_METADATA"
    }
  }]
  depends_on = [
    module.vpc
  ]
}

module "router_nat" {
  source  = "terraform-google-modules/cloud-router/google"
  version = "3.0.0"
  count   = local.use_shared_vpc ? 0 : 1

  project = var.project_id
  name    = "alloydb-default-router"
  network = module.vpc.0.network_name
  region  = var.region

  nats = [{
    name = "alloydb-default-nat"
  }]
  depends_on = [
    module.vpc
  ]
}


module "instance_template" {
  source     = "terraform-google-modules/vm/google//modules/instance_template"
  version    = "7.9.0"
  region     = var.region
  project_id = var.project_id
  subnetwork = local.subnet_name
  service_account = {
    email  = module.sa.email
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }
  machine_type         = "e2-micro"
  source_image_family  = "debian-11"
  source_image_project = "debian-cloud"
  disk_size_gb         = 10
  name_prefix          = "alloydb-psql"
  preemptible          = true
  labels = {
    label = "alloydb"
  }
  depends_on = [
    module.sa,
    google_service_account_iam_binding.sa_token_creator
  ]
}

# module "compute_instance" {
#   source              = "terraform-google-modules/vm/google//modules/compute_instance"
#   version             = "7.9.0"
#   region              = var.region
#   zone                = var.zone
#   subnetwork          = local.subnet_self_link
#   num_instances       = var.num_instances
#   hostname            = "alloydb-cli"
#   instance_template   = module.instance_template.self_link
#   deletion_protection = false
#   depends_on = [
#     module.instance_template
#   ]
# }

# module "iap_tunneling" {
#   source                     = "terraform-google-modules/bastion-host/google//modules/iap-tunneling"
#   version                    = "5.0.1"
#   fw_name_allow_ssh_from_iap = "test-allow-ssh-from-iap-to-tunnel"
#   project                    = var.project_id
#   network                    = local.vpc_self_link
#   service_accounts           = [module.sa.email]
#   instances = [{
#     name = "alloydb-cli-001"
#     zone = var.zone
#   }]
#   members = [
#     "serviceAccount:${var.deployment_service_account_email}"
#   ]
#   depends_on = [
#     module.compute_instance
#   ]
# }


# resource "google_compute_firewall" "default" {
#   name    = "test-firewall"
#   network = google_compute_network.vpc.name

#   allow {
#     protocol = "icmp"
#   }

#   allow {
#     protocol = "tcp"
#     ports    = ["80", "8080", "1000-2000"]
#   }

#   source_tags = ["web"]
# }

# resource "google_compute_network" "default" {
#   name = "test-network"
# }


# # We define a the vm firewall rules:
# module "firewall_rules" {
#   source  = "terraform-google-modules/network/google//modules/firewall-rules"
#   version = "4.1.0"

#   project_id   = var.project
#   network_name = google_compute_network.vpc_network.name

#   rules = [
#     {
#       name                    = "looker-firewall-allow-node-internal"
#       description             = null
#       direction               = "INGRESS"
#       priority                = null
#       ranges                  = [element(module.looker_vpc.subnets_ips, 0)]
#       source_tags             = null
#       source_service_accounts = null
#       target_tags             = ["looker-node"]
#       target_service_accounts = null
#       allow = [{
#         protocol = "tcp"
#         ports    = ["1551", "61616", "1552", "8983", "9090"]
#       }]
#       deny = []
#       log_config = {
#         metadata = "INCLUDE_ALL_METADATA"
#       }
#     },
 
#     },
#     {
#       name                    = "looker-firewall-iap"
#       description             = null
#       direction               = "INGRESS"
#       priority                = null
#       ranges                  = ["35.235.240.0/20"]
#       source_tags             = null
#       source_service_accounts = null
#       target_tags             = null
#       target_service_accounts = null
#       allow = [{
#         protocol = "tcp"
#         ports    = ["22"]
#       }]
#       deny = []
#       log_config = {
#         metadata = "INCLUDE_ALL_METADATA"
#       }
#     }
#   ]
# }

# create private IP range for peering VPCs
# resource "google_compute_global_address" "private_ip_address" {
  
#   provider = google-beta
#   project = var.project_id
#   name          = "private-ip-address"
#   purpose       = "VPC_PEERING"
#   address_type  = "INTERNAL"
#   prefix_length = 16
#   # reference output of resource above and use the attribute
#   network = google_compute_network.vpc_network.id
#   depends_on = [google_compute_network.vpc_network]
# }


# #create vpc connection
# resource "google_service_networking_connection" "private_vpc_connection" {
#   provider = google-beta
#   network                 = google_compute_network.vpc_network.id
#   service                 = "servicenetworking.googleapis.com"
#   reserved_peering_ranges = [google_compute_global_address.private_ip_address.name]
#   depends_on = [google_compute_global_address.private_ip_address]
  
# }


# resource "random_id" "db_name_suffix" {
#   byte_length = 4
# }

# #create BQ dataset
# resource "google_bigquery_dataset" "dataset" {
#   dataset_id                  = "alloydata"
#   friendly_name               = "test"
#   description                 = "This is a test description"
#   location                    = "US"
#   default_table_expiration_ms = 3600000

#   labels = {
#     env = "default"
#   }

#   access {
#     role          = "OWNER"
#     user_by_email = google_service_account.bqowner.email
#   }

#   access {
#     role   = "READER"
#     domain = "hashicorp.com"
#   }
# }
# # Identity and Access Management (IAM) API required
# resource "google_service_account" "bqowner" {
#   account_id = "bqowner"
# }

# resource "null_resource" "provision_alloydb" {
#     provisioner "local-exec" {
#         interpreter = ["/bin/bash", "-c"]
#         command     = <<EOF
# gcloud beta alloydb clusters create ${var.alloycluster} --password=${var.alloyclusterpassword} --network=${var.vpcname} --region=${var.region} --project=${var.project_id}
# gcloud beta alloydb instances create ${var.alloyinstance} --instance-type=${var.alloyinstancetype} --cpu-count=${var.alloyinstancecpuecount} --region=${var.region} --cluster=${var.alloycluster} --project=${var.project_name}
# EOF
#         }
#         depends_on = [google_service_networking_connection.private_vpc_connection]
# }


#https://medium.com/google-cloud/a-hitchhikers-guide-to-gcp-service-account-impersonation-in-terraform-af98853ebd37

# module "dataflow-job" {
#   source                = "../../"
#   project_id            = var.project_id
#   name                  = "dlp_example_${null_resource.download_sample_cc_into_gcs.id}_${null_resource.deinspection_template_setup.id}"
#   on_delete             = "cancel"
#   region                = var.region
#   zone                  = "${var.region}-a"
#   template_gcs_path     = "gs://dataflow-templates/latest/Stream_DLP_GCS_Text_to_BigQuery"
#   temp_gcs_location     = module.dataflow-bucket.name
#   service_account_email = var.service_account_email
#   max_workers           = 5

#   parameters = {
#     inputFilePattern       = "gs://${module.dataflow-bucket.name}/cc_records.csv"
#     datasetName            = google_bigquery_dataset.default.dataset_id
#     batchSize              = 1000
#     dlpProjectId           = var.project_id
#     deidentifyTemplateName = "projects/${var.project_id}/deidentifyTemplates/15"
#   }
# }

# resource "null_resource" "destroy_deidentify_template" {
#   triggers = {
#     project_id = var.project_id
#   }

# We define a the vm firewall rules:
# module "vm-looker-firewall_rules" {
#   source  = "terraform-google-modules/network/google//modules/firewall-rules"
#   version = "4.1.0"

#   project_id   = var.project
#   network_name = module.looker_vpc.network_name

#   rules = [
#     {
#       name                    = "looker-firewall-allow-node-internal"
#       description             = null
#       direction               = "INGRESS"
#       priority                = null
#       ranges                  = [element(module.looker_vpc.subnets_ips, 0)]
#       source_tags             = null
#       source_service_accounts = null
#       target_tags             = ["looker-node"]
#       target_service_accounts = null
#       allow = [{
#         protocol = "tcp"
#         ports    = ["1551", "61616", "1552", "8983", "9090"]
#       }]
#       deny = []
#       log_config = {
#         metadata = "INCLUDE_ALL_METADATA"
#       }
#     },
#     {
#       name                    = "looker-firewall-allow-nfs-internal"
#       description             = null
#       direction               = "INGRESS"
#       priority                = null
#       ranges                  = [element(module.looker_vpc.subnets_ips, 0)]
#       source_tags             = null
#       source_service_accounts = null
#       target_tags             = ["looker"]
#       target_service_accounts = null
#       allow = [{
#         protocol = "tcp"
#         ports    = ["2049", "4045", "111", "2046"]
#       }]
#       deny = []
#       log_config = {
#         metadata = "INCLUDE_ALL_METADATA"
#       }
#     },
#     {
#       name                    = "looker-firewall-gfe"
#       description             = null
#       direction               = "INGRESS"
#       priority                = null
#       ranges                  = ["130.211.0.0/22", "35.191.0.0/16"]
#       source_tags             = null
#       source_service_accounts = null
#       target_tags             = ["looker-node"]
#       target_service_accounts = null
#       allow = [{
#         protocol = "tcp"
#         ports    = ["9999", "19999"]
#       }]
#       deny = []
#       log_config = {
#         metadata = "INCLUDE_ALL_METADATA"
#       }
#     },
#     {
#       name                    = "looker-firewall-iap"
#       description             = null
#       direction               = "INGRESS"
#       priority                = null
#       ranges                  = ["35.235.240.0/20"]
#       source_tags             = null
#       source_service_accounts = null
#       target_tags             = null
#       target_service_accounts = null
#       allow = [{
#         protocol = "tcp"
#         ports    = ["22"]
#       }]
#       deny = []
#       log_config = {
#         metadata = "INCLUDE_ALL_METADATA"
#       }
#     }
#   ]
# }
# Set up Private Services access. Private Services are used to securely connect
# to Cloud SQL, Filestore, and Memorystore
# module "private_service_access" {
#   source  = "GoogleCloudPlatform/sql-db/google//modules/private_service_access"
#   version = "9.0.0"

#   project_id    = var.project
#   vpc_network   = element(split("/", module.looker_vpc.network_self_link), length(split("/", module.looker_vpc.network_self_link)) - 1) # https://github.com/terraform-google-modules/terraform-google-sql-db/issues/176
#   address       = local.private_ip_start
#   ip_version    = "IPV4"
#   prefix_length = local.private_ip_block
# }

# module "cloud_router" {
#   source  = "terraform-google-modules/cloud-router/google"
#   version = "1.3.0"

#   project = var.project
#   name    = "looker-router"
#   network = module.looker_vpc.network_name
#   region  = var.region

#   nats = [{
#     name = "looker-nat"
#   }]
# }

# # We define a the vm firewall rules:
# module "vm-looker-firewall_rules" {
#   source  = "terraform-google-modules/network/google//modules/firewall-rules"
#   version = "4.1.0"

#   project_id   = var.project
#   network_name = module.looker_vpc.network_name

#   rules = [
#     {
#       name                    = "looker-firewall-allow-node-internal"
#       description             = null
#       direction               = "INGRESS"
#       priority                = null
#       ranges                  = [element(module.looker_vpc.subnets_ips, 0)]
#       source_tags             = null
#       source_service_accounts = null
#       target_tags             = ["looker-node"]
#       target_service_accounts = null
#       allow = [{
#         protocol = "tcp"
#         ports    = ["1551", "61616", "1552", "8983", "9090"]
#       }]
#       deny = []
#       log_config = {
#         metadata = "INCLUDE_ALL_METADATA"
#       }
#     },
#     {
#       name                    = "looker-firewall-allow-nfs-internal"
#       description             = null
#       direction               = "INGRESS"
#       priority                = null
#       ranges                  = [element(module.looker_vpc.subnets_ips, 0)]
#       source_tags             = null
#       source_service_accounts = null
#       target_tags             = ["looker"]
#       target_service_accounts = null
#       allow = [{
#         protocol = "tcp"
#         ports    = ["2049", "4045", "111", "2046"]
#       }]
#       deny = []
#       log_config = {
#         metadata = "INCLUDE_ALL_METADATA"
#       }
#     },
#     {
#       name                    = "looker-firewall-gfe"
#       description             = null
#       direction               = "INGRESS"
#       priority                = null
#       ranges                  = ["130.211.0.0/22", "35.191.0.0/16"]
#       source_tags             = null
#       source_service_accounts = null
#       target_tags             = ["looker-node"]
#       target_service_accounts = null
#       allow = [{
#         protocol = "tcp"
#         ports    = ["9999", "19999"]
#       }]
#       deny = []
#       log_config = {
#         metadata = "INCLUDE_ALL_METADATA"
#       }
#     },
#     {
#       name                    = "looker-firewall-iap"
#       description             = null
#       direction               = "INGRESS"
#       priority                = null
#       ranges                  = ["35.235.240.0/20"]
#       source_tags             = null
#       source_service_accounts = null
#       target_tags             = null
#       target_service_accounts = null
#       allow = [{
#         protocol = "tcp"
#         ports    = ["22"]
#       }]
#       deny = []
#       log_config = {
#         metadata = "INCLUDE_ALL_METADATA"
#       }
#     }
#   ]
# }
