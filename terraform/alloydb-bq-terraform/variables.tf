variable "project_name" {
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
  default     = "us-central1c"
}

variable "subnetwork" {
  description = "The subnetwork selflink to host the compute instances in"
  type        = string
  default     = ""
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

variable "nat_ip" {
  description = "Public ip address"
  type        = string
  default     = "us-central1c"
}

variable "vpcname" {
  description = "Name of the VPC the databases will be deployed in"
  type        = string
  default     = "alloyvpc"
}


variable "rangename" {
  description = "Name of range"
  type        = string
  default     = "vpcrange"
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

varaible "deployment_service_account_email" {
  type = string
  description = " service accouint email"
}