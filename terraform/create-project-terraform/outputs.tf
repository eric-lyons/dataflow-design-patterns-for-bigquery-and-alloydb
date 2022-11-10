
output "project_id" {
  value       = module.project_factory.project_id
  description = "The ID of the created project"
}

output "project_number" {
  value       = module.project_factory.project_number
  description = "The project number of the created project"
}

output "deployment_service_account_email" {
  value       = module.project_factory.service_account_email
  description = "The deployment service account email"
}

output "gcs_buckets" {
  description = "GCS bucket"
  value = {
    remote-state-gcs-name = module.gcs_buckets.name
  }
}