/*
###### ###### ###### ###### ###### 
### Amazon VPC ###
###### ###### ###### ###### ###### 

Based on source:: https://github.com/terraform-aws-modules/terraform-aws-vpc
# example # https://github.com/terraform-aws-modules/terraform-aws-vpc/tree/master/examples

*/

##### ##### ##### ##### ##### ##### ##### ##### ##### ##### ##### 
## Create VPC with 1 x Public && 1 x Private Main Subnets
##### ##### ##### ##### ##### ##### ##### ##### ##### ##### ##### 

data "aws_availability_zones" "available" {}

locals {
    name   = ""
    region = var.aws_region_location

    azs = slice(data.aws_availability_zones.available.names, 0, 3)

    private_subnets = [var.main-vpc-private-cidr]
    public_subnets  = [var.main-vpc-public-cidr]
}

################################################################################
# VPC Module
################################################################################
// Create VPC with Main Public and Private Subnets

# Provides an Elastic IP resource
resource "aws_eip" "nat" {
  count = 1

  # vpc = true :: (Deprecated) https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eip
  domain = "vpc"

  tags = merge(
    {
      Name = "nat"
    },
    local.tags,
  )
}

module "vpc" {
    source  = "terraform-aws-modules/vpc/aws"
    version = ">= 5.17.0" # Use the desired version of the module

    name = var.vpc_name
    cidr = var.vpc_cidr

    azs             = local.azs               # Availability zones for subnets
    private_subnets = local.private_subnets   # Private subnets
    public_subnets  = local.public_subnets    # Public subnets
    
    enable_dns_support = true    # Enable DNS support (default is true)
    enable_dns_hostnames = true  # Enable DNS hostnames (default is false in custom VPCs)

    enable_nat_gateway     = true
    single_nat_gateway     = true
    one_nat_gateway_per_az = false
    reuse_nat_ips          = true             # <= Skip creation of EIPs for the NAT Gateways (resource "aws_eip" "nat")
    external_nat_ip_ids    = aws_eip.nat.*.id # <= IPs specified here as input to the module

    # Create AWS VPN Gateway
    # enable_vpn_gateway = true
    
    #   manage_default_security_group = false
    #   manage_default_network_acl = false
    default_route_table_name    = "default-rt-${var.env_name}"
    default_security_group_name = "default-${var.env_name}-sg"
    default_network_acl_name    = "default-acl-network-${var.env_name}"

    tags = local.tags

    private_subnet_tags = {
        "Name" = try(
            format("${var.prefix_private_subnet_name}-${var.suffix_subnet_name}"), "private--main--subnet"
        )
    }

    public_subnet_tags = {
        "Name" = "${var.prefix_public_subnet_name}-${var.suffix_subnet_name}"
    }
    
    igw_tags = {
        Name = "internet-gw-${var.env_name}"
    }
    nat_gateway_tags = {
        Name = "nat-gw-${var.env_name}"
    }

    private_route_table_tags = {
        Name = "private-rt-${var.env_name}"
    }
    
    public_route_table_tags = {
        Name = "public-rt-${var.env_name}"
    }
}

