/*
###### ###### ###### ###### ###### 
### Subnets ###
###### ###### ###### ###### ###### 

Based on source:: https://github.com/terraform-aws-modules/terraform-aws-vpc
# example # https://github.com/terraform-aws-modules/terraform-aws-vpc/blob/master/main.tf
*/

locals {
  private_subnets_values = {
    eks-private = {
      # Create private subnets for EKS (K8s)
      name               = "eks"
      azs                = ["${var.aws_region_location}a", "${var.aws_region_location}b", "${var.aws_region_location}c"]
      subnet_cidr        = ["${var.eks-subnet-01-private-cidr}", "${var.eks-subnet-02-private-cidr}", "${var.eks-subnet-03-private-cidr}"]
      single_nat_gateway = true
      additional_tags = {
        AWS_Service                                       = "eks"
        "kubernetes.io/role/internal-elb"                 = 1
        "kubernetes.io/cluster/${local.eks_cluster_name}" = "owned"
      }
    },
    redis-private = {
      # Create private subnets for Redis
      name               = "redis"
      azs                = ["${var.aws_region_location}a", "${var.aws_region_location}b"]
      subnet_cidr        = ["${var.redis-subnet-01-private-cidr}", "${var.redis-subnet-02-private-cidr}"]
      single_nat_gateway = true
      additional_tags = {
        AWS_Service = "redis"
      }
    }
  }
  public_subnets_values = {
    eks-public = {
      # Create public subnets for EKS (K8s)
      name               = "eks"
      azs                = ["${var.aws_region_location}a", "${var.aws_region_location}b", "${var.aws_region_location}c"]
      subnet_cidr        = ["${var.eks-subnet-01-public-cidr}", "${var.eks-subnet-02-public-cidr}", "${var.eks-subnet-03-public-cidr}"]
      single_nat_gateway = true
      additional_tags = {
        AWS_Service                                       = "eks"
        "kubernetes.io/role/elb"                          = 1
        "kubernetes.io/cluster/${local.eks_cluster_name}" = "owned"
      }
    }
  }
}

data "aws_route_table" "private" {
  filter {
    name   = "tag:Name"
    values = ["private-rt-${var.env_name}"] # insert values here
  }
  depends_on = [module.vpc]
}

data "aws_route_table" "public" {
  filter {
    name   = "tag:Name"
    values = ["public-rt-${var.env_name}"] # insert values here
  }
  depends_on = [module.vpc]
}

####################################################
### Create Private Subnets ###
####################################################
module "create-private-subnets" {
  source = "../../modules/network"

  for_each = local.private_subnets_values
  azs             = each.value["azs"]                   # Availability Zones for private subnet
  private_subnets = try(each.value["subnet_cidr"], [])  # Provide the CIDR blocks for the private subnets

  vpc_id = module.vpc.vpc_id

  single_nat_gateway     = each.value["single_nat_gateway"] # "HaHana LeMazgan" this needed if some resorse will have multiple NAT's GW
  private_route_table_id = data.aws_route_table.private.id

  tags = merge(local.tags, each.value["additional_tags"])

  name = each.value["name"]
}

####################################################
### Create Public Subnets ###
####################################################
module "create-public-subnets" {
  source = "../../modules/network"

  for_each        = local.public_subnets_values
  azs             = each.value["azs"]                   # Availability Zones for public subnet
  public_subnets  = try(each.value["subnet_cidr"], [])  # Provide the CIDR blocks for the public subnets

  # Reference the existing VPC ID
  vpc_id = module.vpc.vpc_id

  single_nat_gateway     = each.value["single_nat_gateway"] 
  public_route_table_id = data.aws_route_table.public.id

  tags = merge(local.tags, each.value["additional_tags"])

  name = each.value["name"]
}