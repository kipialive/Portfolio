/*
###### ###### ###### ###### ###### ###### ######
### Amazon Application Load Balancer (ALB) ###
###### ###### ###### ###### ###### ###### ######

Based on source:: https://github.com/terraform-aws-modules/terraform-aws-alb
# example # 
  https://github.com/terraform-aws-modules/terraform-aws-alb/blob/master/examples/complete-alb/main.tf
  https://github.com/terraform-aws-modules/terraform-aws-autoscaling/blob/master/examples/complete/main.tf

*/

locals {
  alb_name_internal_backend = "backend-${var.env_name_short}-int-alb"
  domain_name = "warabej793.com"
}




##############################
### Internal ALB:: Back-End ###
############################## 

module "alb-internal-backend" {
  source  = "terraform-aws-modules/alb/aws"
  version = ">= 9.13.0" # Use the desired version of the module

  # Disable creation of the LB and all resources
  # create = false

  name = local.alb_name_internal_backend

  load_balancer_type                = "application"
  internal                          = true

  # dns_record_client_routing_policy = "availability_zone_affinity"
  vpc_id                            = module.vpc.vpc_id
  subnets                           = data.aws_subnets.main_private_subnets.ids

  # # Use `subnet_mapping` to attach EIPs
  # subnet_mapping = [for i, eip in aws_eip.this :
  #   {
  #     allocation_id = eip.id
  #     subnet_id     = module.vpc.private_subnets[i]
  #   }
  # ]

  # # For example only
  enable_deletion_protection = false

  # Security Group
  security_group_ingress_rules = {
    all_http = {
      from_port   = 3000
      to_port     = 3000
      ip_protocol = "tcp"
      description = "HTTP web traffic"
      cidr_ipv4   = "${var.vpc_cidr}"
    }
  }
  
  security_group_egress_rules = {
    all = {
      ip_protocol = "-1"
      cidr_ipv4   = module.vpc.vpc_cidr_block
    }
  }

  # access_logs = {
  #   bucket = module.log_bucket.s3_bucket_id
  #   prefix = "access-logs"
  # }

  listeners = {
    ex-main = {
      port     = 3000
      protocol = "HTTP"
      
      forward = {
        target_group_key = "ex-target-main"
      }
    }    
  }

  target_groups = {
    ex-target-main = {
      backend_protocol                  = "HTTP"
      backend_port                      = 3000
      target_type                       = "instance"
      deregistration_delay              = 5
      load_balancing_cross_zone_enabled = true

      # There's nothing to attach here in this definition.
      # The attachment happens in the ASG module above
      port              = 3000
      create_attachment = false

      health_check = {
        enabled             = true
        interval            = 30
        path                = "/healthz"
        port                = 3000
        healthy_threshold   = 3
        unhealthy_threshold = 3
        timeout             = 5
        protocol            = "HTTP"
        matcher             = "200"
      }
    }
  }

  # Route53 Record(s)
  route53_records = {
    A = {
      name    = local.alb_name_internal_backend
      type    = "A"
      zone_id = data.aws_route53_zone.this.id
    }
    AAAA = {
      name    = local.alb_name_internal_backend
      type    = "AAAA"
      zone_id = data.aws_route53_zone.this.id
    }
  }

  tags = local.tags
}

output "alb_arn" {
  value = module.alb-internal-backend.arn
}

output "alb_dns_name" {
  value = module.alb-internal-backend.dns_name
}

################################################################################
# Supporting resources
################################################################################

data "aws_route53_zone" "this" {
  name = local.domain_name
}