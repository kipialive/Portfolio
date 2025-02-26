locals {
  len_public_subnets      = max(length(var.public_subnets), length(var.public_subnet_ipv6_prefixes))
  len_private_subnets     = max(length(var.private_subnets), length(var.private_subnet_ipv6_prefixes))
#   len_database_subnets    = max(length(var.database_subnets), length(var.database_subnet_ipv6_prefixes))
#   len_elasticache_subnets = max(length(var.elasticache_subnets), length(var.elasticache_subnet_ipv6_prefixes))
#   len_redshift_subnets    = max(length(var.redshift_subnets), length(var.redshift_subnet_ipv6_prefixes))
#   len_intra_subnets       = max(length(var.intra_subnets), length(var.intra_subnet_ipv6_prefixes))
#   len_outpost_subnets     = max(length(var.outpost_subnets), length(var.outpost_subnet_ipv6_prefixes))

#   max_subnet_length = max(
#     local.len_private_subnets,
#     local.len_public_subnets,
#     local.len_intra_subnets,
#     local.len_elasticache_subnets,
#     local.len_database_subnets,
#     local.len_redshift_subnets,
#   )

#   # Use `local.vpc_id` to give a hint to Terraform that subnets should be deleted before secondary CIDR blocks can be free!
#   vpc_id = try(aws_vpc_ipv4_cidr_block_association.this[0].vpc_id, aws_vpc.this[0].id, "")

  create_vpc = var.create_vpc
}

################################################################################
# Private Subnets
################################################################################

locals {
  create_private_subnets = local.create_vpc && local.len_private_subnets > 0
}

resource "aws_subnet" "private" {
  count = local.create_private_subnets ? local.len_private_subnets : 0

  assign_ipv6_address_on_creation                = var.enable_ipv6 && var.private_subnet_ipv6_native ? true : var.private_subnet_assign_ipv6_address_on_creation
  availability_zone                              = length(regexall("^[a-z]{2}-", element(var.azs, count.index))) > 0 ? element(var.azs, count.index) : null
  availability_zone_id                           = length(regexall("^[a-z]{2}-", element(var.azs, count.index))) == 0 ? element(var.azs, count.index) : null
  cidr_block                                     = var.private_subnet_ipv6_native ? null : element(concat(var.private_subnets, [""]), count.index)
  enable_dns64                                   = var.enable_ipv6 && var.private_subnet_enable_dns64
  enable_resource_name_dns_aaaa_record_on_launch = var.enable_ipv6 && var.private_subnet_enable_resource_name_dns_aaaa_record_on_launch
  enable_resource_name_dns_a_record_on_launch    = !var.private_subnet_ipv6_native && var.private_subnet_enable_resource_name_dns_a_record_on_launch
#   ipv6_cidr_block                                = var.enable_ipv6 && length(var.private_subnet_ipv6_prefixes) > 0 ? cidrsubnet(aws_vpc.this[0].ipv6_cidr_block, 8, var.private_subnet_ipv6_prefixes[count.index]) : null
  ipv6_native                                    = var.enable_ipv6 && var.private_subnet_ipv6_native
  private_dns_hostname_type_on_launch            = var.private_subnet_private_dns_hostname_type_on_launch
  vpc_id                                         = var.vpc_id # local.vpc_id

  tags = merge(
    {
      Name = try(
        var.private_subnet_names[count.index],
        format("${var.private_subnet_suffix}-${var.name}-subnet-${count.index + 1}")
        # format("${var.name}-${var.private_subnet_suffix}-%s", element(var.azs, count.index))
      )
      SubnetType = var.private_subnet_suffix
      Zone = try(var.private_subnet_names[count.index], format("%s", element(var.azs, count.index)))
    },
    var.tags,
    var.private_subnet_tags,
    lookup(var.private_subnet_tags_per_az, element(var.azs, count.index), {})
  )
}


resource "aws_route_table_association" "private" {
  count = local.create_private_subnets ? local.len_private_subnets : 0

  subnet_id = element(aws_subnet.private[*].id, count.index)
  route_table_id = var.private_route_table_id
#   route_table_id = element(
#     aws_route_table.private[*].id,
#     var.single_nat_gateway ? 0 : count.index,
#   )
}

################################################################################
# Publiс Subnets
################################################################################

locals {
  create_public_subnets = local.create_vpc && local.len_public_subnets > 0
}

resource "aws_subnet" "public" {
  count = local.create_public_subnets ? local.len_public_subnets : 0

  assign_ipv6_address_on_creation                = var.enable_ipv6 && var.public_subnet_ipv6_native ? true : var.public_subnet_assign_ipv6_address_on_creation
  availability_zone                              = length(regexall("^[a-z]{2}-", element(var.azs, count.index))) > 0 ? element(var.azs, count.index) : null
  availability_zone_id                           = length(regexall("^[a-z]{2}-", element(var.azs, count.index))) == 0 ? element(var.azs, count.index) : null
  cidr_block                                     = var.public_subnet_ipv6_native ? null : element(concat(var.public_subnets, [""]), count.index)
  enable_dns64                                   = var.enable_ipv6 && var.public_subnet_enable_dns64
  enable_resource_name_dns_aaaa_record_on_launch = var.enable_ipv6 && var.public_subnet_enable_resource_name_dns_aaaa_record_on_launch
  enable_resource_name_dns_a_record_on_launch    = !var.public_subnet_ipv6_native && var.public_subnet_enable_resource_name_dns_a_record_on_launch
  # ipv6_cidr_block                                = var.enable_ipv6 && length(var.public_subnet_ipv6_prefixes) > 0 ? cidrsubnet(aws_vpc.this[0].ipv6_cidr_block, 8, var.public_subnet_ipv6_prefixes[count.index]) : null
  ipv6_native                                    = var.enable_ipv6 && var.public_subnet_ipv6_native
  map_public_ip_on_launch                        = var.map_public_ip_on_launch
  private_dns_hostname_type_on_launch            = var.public_subnet_private_dns_hostname_type_on_launch
  vpc_id                                         = var.vpc_id # local.vpc_id

  tags = merge(
    {
      Name = try(
        var.public_subnet_names[count.index],
        format("${var.public_subnet_suffix}-${var.name}-subnet-${count.index + 1}")
        # format("${var.name}-${var.public_subnet_suffix}-%s", element(var.azs, count.index))
      )
    },
    var.tags,
    var.public_subnet_tags,
    lookup(var.public_subnet_tags_per_az, element(var.azs, count.index), {})
  )
}

# resource "aws_route_table" "public" {
#   count = local.create_public_subnets ? 1 : 0

#   vpc_id = local.vpc_id

#   tags = merge(
#     { "Name" = "${var.name}-${var.public_subnet_suffix}" },
#     var.tags,
#     var.public_route_table_tags,
#   )
# }

resource "aws_route_table_association" "public" {
  count = local.create_public_subnets ? local.len_public_subnets : 0

  subnet_id      = element(aws_subnet.public[*].id, count.index)
  route_table_id = var.public_route_table_id
  # route_table_id = aws_route_table.public[0].id
}

# resource "aws_route" "public_internet_gateway" {
#   count = local.create_public_subnets && var.create_igw ? 1 : 0

#   route_table_id         = aws_route_table.public[0].id
#   destination_cidr_block = "0.0.0.0/0"
#   gateway_id             = aws_internet_gateway.this[0].id

#   timeouts {
#     create = "5m"
#   }
# }
