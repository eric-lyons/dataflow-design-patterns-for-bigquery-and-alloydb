variable "project_id" {
  description = "Value of the GCP Project the databases and pipeline will be defined in"
  type        = string
  default     = "lyons-terraform-sandbox"
}

variable "region" {
  description = "Value of the GCP region the resources will be deployed in"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "Value of the GCP zone the resources will be deployed in"
  type        = string
  default     = "us-central1-c"
}


variable "num_instances" {
  description = "number of VM instances deployed"
  type        = number
  default     = 1
}

variable "network_tier" {
  description = "Public ip address"
  type        = string
  default     = "PREMIUM"
}

variable "vpc_subnet_range" {
  description = "Public ip address"
  type        = string
  default     = "10.0.0.0/20"
}

variable "vpcname" {
  description = "Name of the VPC the databases will be deployed in"
  type        = string
  default     = "alloyvpc"
}

variable "network_config" {
  description = "Shared VPC network configurations to use. If null networks will be created in projects with preconfigured values."
  type = object({
    host_project      = string
    network_name      = string
    network_self_link = string
    subnet_self_links = object({
      subnet_name      = string
      subnet_self_link = string
    })
    composer_ip_ranges = object({
      cloudsql   = string
      gke_master = string
      web_server = string
    })
    composer_secondary_ranges = object({
      pods     = string
      services = string
    })
  })
  default = null
}

variable "project_number" {
  type        = string
  description = "The GCP Project Number"
  validation {
    condition     = length(var.project_number) > 0
    error_message = "The project_id is required."
  }
}

variable "alloycluster" {
  description = "Name of alloydb cluster"
  type        = string
  default     = "thealloycluser"
}

variable "alloyclusterpassword" {
  description = "Name of alloydb instance"
  type        = string
  default     = "passwordforinstance"
}

variable "alloyinstance" {
  description = "Name of alloydb instance"
  type        = string
  default     = "thealloyinstance"
}

variable "alloyinstancecpuecount" {
  description = "count of alloydbcpu"
  type        = number
  default     = 8
}

variable "alloyinstancetype" {
  description = "type of alloy instance"
  type        = string
  default     = "PRIMARY"
}

variable "deployment_service_account_email" {
  type = string
  description = " service accouint email"
}