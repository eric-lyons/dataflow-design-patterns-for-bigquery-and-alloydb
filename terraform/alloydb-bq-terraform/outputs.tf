
output "network_name" {
  value       = module.vpc.0.network_name
  description = "The name of the VPC being created"
}

output "network_self_link" {
  value       = module.vpc.0.network_self_link
  description = "The URI of the VPC being created"
}


output "subnets_names" {
  value       = module.vpc.0.subnets_names[0]
  description = "The names of the subnets being created"
}

# output "subnets_ips" {
#   value       = module.vpc.subnets_ips
#   description = "The IP and cidrs of the subnets being created"
# }

# output "subnets_regions" {
#   value       = module.vpc.subnets_regions
#   description = "The region where subnets will be created"
# }

# # output "subnets_private_access" {
# #   value       = module.vpc.subnets_private_access
# #   description = "Whether the subnets will have access to Google API's without a public IP"
# # }