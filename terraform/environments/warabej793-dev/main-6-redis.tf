/*
###### ###### ###### ###### ###### ###### 
### Amazon ElastiCache for Redis ###
###### ###### ###### ###### ###### ###### 

Based on source:: https://github.com/terraform-aws-modules/terraform-aws-elasticache
# example   # https://github.com/terraform-aws-modules/terraform-aws-elasticache/blob/master/examples/redis-cluster-mode/main.tf
            # https://github.com/terraform-aws-modules/terraform-aws-elasticache/blob/master/examples/redis-cluster/main.tf
*/

################################################################################
# ElastiCache Module
################################################################################

locals {
  redis_name        = "redis-${var.env_name_short}"
  engine_version    = "7.1"
  node_type         = "cache.t4g.micro"
  family            = "redis7" # https://docs.aws.amazon.com/AmazonElastiCache/latest/APIReference/API_CreateCacheParameterGroup.html
}

data "aws_subnets" "redis-private-subnets" {
  filter {
    name   = "tag:DeliveryType"
    values = ["Terraform"]
  }
  filter {
    name   = "tag:AWS_Service"
    values = ["redis"]
  }
  filter {
    name   = "tag:Environment"
    values = ["${var.env_name_short}"]
  }
  depends_on = [
    module.create-private-subnets["redis-private"]
  ]
}

# output "redis-private-subnets" {
#   value = data.aws_subnets.redis-private-subnets.ids
# }

module "redis-elasticache" {
  source = "terraform-aws-modules/elasticache/aws"
  version = ">= 1.4.1" # Use the desired version of the module

  description = "Redis Cluster with 1 node on ${var.vpc_name}"

  cluster_id               = local.redis_name
  create_cluster           = true
  # Create Redis wih one node
  create_replication_group = false

#   # Clustered mode
#   cluster_mode_enabled       = true
#   num_node_groups            = 2
#   replicas_per_node_group    = 3
#   automatic_failover_enabled = true
#   multi_az_enabled           = true

  engine_version = local.engine_version
  node_type      = local.node_type

  maintenance_window = "sun:05:00-sun:09:00"
  apply_immediately  = true

  # Security Group
  vpc_id = module.vpc.vpc_id
  security_group_rules = {
    ingress_vpc = {
      # Default type is `ingress`
      # Default port is based on the default engine port
      description = "VPC traffic"
      cidr_ipv4   = module.vpc.vpc_cidr_block
    }
  }

  # Subnet Group
  subnet_group_name        = local.redis_name
  subnet_group_description = "${title(local.redis_name)} subnet group"
  subnet_ids               = data.aws_subnets.redis-private-subnets.ids

  # Parameter Group
  create_parameter_group      = true
  parameter_group_name        = local.redis_name
  parameter_group_family      = local.family
  parameter_group_description = "${title(local.redis_name)} parameter group"
  parameters = [
    {
      name  = "latency-tracking"
      value = "yes"
    }
  ]

  tags = merge(local.tags, {
    Name  = local.redis_name
  })
}
