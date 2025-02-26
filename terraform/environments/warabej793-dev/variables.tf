// AWS Account ID 
variable "allowed_account_ids" {
  description = "List of allowed AWS account ids where resources can be created"
  type        = list(string)
  default     = []
}

variable "aws_account_id" {
  description = "AWS account ID where resources can be created"
  type        = string
  default     = ""
}

variable "env_name" {
  description = "Environment name e.g., 'prod-env', 'staging-env', 'dev-env', 'UAT-env' ... etc."
  type        = string
  default     = ""
}

variable "env_name_short" {
  description = "Short version of environment name e.g., 'prod', 'staging', 'dev', 'UAT' ... etc."
  type        = string
  default     = ""
}

// Region Location
variable "aws_region_location" {
  description = "The AWS region I will use is ..."
  type        = string
  default     = ""
}

// Availability Zone (az)
variable "azs" {
  description = "A list of availability zones in the region"
  type        = list(string)
  default     = []
}

variable "public_zones" {
    description = "A list of public zones in the region"
    type        = list(string)
    default     = []
}

variable "public_zones_m" {
    description = "A map of public zones in the region"
    type        = map(string)
    default     = {}
}

variable "private_zones" {
  description = "A list of private zones in the region"
  type        = list(string)
  default     = []
}

variable "private_zones_m" {
  description = "A map of private zones in the region"
  type        = map(string)
  default     = {}
}

################################################################################
# VPC
################################################################################

variable "vpc_name" {
  description = "VPC name to be used on all the resources as identifier"
  type        = string
  default     = ""
}

// VPC CIDR blocks/range
variable "vpc_cidr" {
  description = "The AWS VPC CIDR blocks/range I will use is ..."
  type        = string
  default     = ""
}

variable "main-vpc-public-cidr" {
  description = "Main VPC CIDR blocks/range for Public Subnet"
  type        = string
  default     = ""
}

variable "main-vpc-private-cidr" {
  description = "Main VPC CIDR blocks/range for Private Subnet"
  type        = string
  default     = ""
}

################################################################################
# Subnets
################################################################################

variable "prefix_private_subnet_name" {
  type    = string
  default = "private"
}

variable "prefix_public_subnet_name" {
  type    = string
  default = "public"
}

variable "suffix_subnet_name" {
  type    = string
  default = "main-vpc-subnet"
}

################################################################################
# Elastic Kubernetes Service (EKS) - K8s Subnets
################################################################################

variable "eks-subnet-01-private-cidr" {
  description = "EKS - First Private Subnet"
  type        = string
  default     = ""
}

variable "eks-subnet-02-private-cidr" {
  description = "EKS - Second Private Subnet"
  type        = string
  default     = ""
}

variable "eks-subnet-03-private-cidr" {
  description = "EKS - Third Private Subnet"
  type        = string
  default     = ""
}

variable "eks-subnet-01-public-cidr" {
  description = "EKS - First Public Subnet"
  type        = string
  default     = ""
}

variable "eks-subnet-02-public-cidr" {
  description = "EKS - Second Public Subnet"
  type        = string
  default     = ""
}

variable "eks-subnet-03-public-cidr" {
  description = "EKS - Third Public Subnet"
  type        = string
  default     = ""
}

################################################################################
# ElastiCache for Redis Subnets
################################################################################

variable "redis-subnet-01-private-cidr" {
  description = "Redis - First Private Subnet"
  type        = string
  default     = ""
}

variable "redis-subnet-02-private-cidr" {
  description = "Redis - Second Private Subnet"
  type        = string
  default     = ""
}

################################################################################
# Tags - Map of tags assigned to the resource (valiable with "map" type)
################################################################################

locals {
  tags = {
    # Description    = local.name
    Environment     = "${var.env_name_short}"
    GitRepo         = "affico-terraform"
    Owner           = "DevOps"
    DeliveryType    = "Terraform"
  }
}

variable "additional_tags" {
  description = "A map of tags to add to all additional resources"
  type        = map(string)
  default     = {}
}

#######################################################
### Amazon EC2:: Key Pair Management ###
#######################################################

variable "save_pem_locally" {
  description = "Whether to save the created Key-pair PEM file locally"
  type        = bool
  default     = false
}

variable "create_new_key_pair" {
  description = "Determines whether resources will be created (affects all resources)"
  type        = bool
  default     = true
}