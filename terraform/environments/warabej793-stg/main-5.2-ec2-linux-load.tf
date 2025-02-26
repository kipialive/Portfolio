/*
###### ###### ###### ###### ###### ######
### LoadTest on AWS EC2 - Ubuntu OS ###
###### ###### ###### ###### ###### ######

Based on source:: https://github.com/terraform-aws-modules/terraform-aws-ec2-instance
tutorials: 
    https://medium.com/@aeroleonsconsultancy/setting-up-loadtest-on-amazon-ec2-a-comprehensive-guide-d1489732096d
    https://www.loadtest.com/docs/install-debian
*/

locals {
  ec2_loadtest_name                           = "loadtest-${var.env_name_short}"
  ec2_loadtest_root_block_device_volume_size  = 20
  ec2_loadtest_instance_type                  = "t2.medium" # Change to "xxxxxxxx"

  ec2_loadtest_user_data              = <<-EOT
    #!/bin/bash
    echo "Hello Terraform!"

    ### Install CloudWatch Agent ###
    sudo yum install -y amazon-cloudwatch-agent

    ### Test ###
    {
      echo "CloudWatch Agent status: $(sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a status | jq '.status')"

    } > /$APP_FOLDER/versions.txt    
  EOT

  # loadtest_ec2_subdomain          = "prod-roc.loadtest"
}

# Get latest Ubuntu Server 24.04 LTS AMI
data "aws_ami" "ubuntu-24_dot_04" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }
}

output "ubuntu-server-24_dot_04-AMI" {
  value = data.aws_ami.ubuntu-24_dot_04.id
}

##################################
### Ubuntu Server for LoadTest ###
##################################
## Ubuntu Server 24.04 LTS (HVM), SSD Volume Type
## Description:: Canonical, Ubuntu, 24.04, amd64 noble image build on 2025-01-15

module "ec2-ubuntu-server-loadtest" {
  source = "terraform-aws-modules/ec2-instance/aws"
  version = ">= 5.7.1"

  # create = false

  name = local.ec2_loadtest_name

  ami                     = data.aws_ami.ubuntu-24_dot_04.id # uncoment this line to get latest ami version 
  # ami                    = "ami-07d2649d67dbe8900" # Exist only in N. California (us-west-1)
  ignore_ami_changes      = true
  
  instance_type           = local.ec2_loadtest_instance_type
  availability_zone       = data.aws_subnet.main_private_subnet.availability_zone
  subnet_id               = data.aws_subnet.main_private_subnet.id
  # vpc_security_group_ids  = [module.loadtest-security-group.security_group_id]
  vpc_security_group_ids  = [module.linux-security-group.security_group_id]
  #   placement_group             = aws_placement_group.web.id
  associate_public_ip_address = false
  # source_dest_check = false
  key_name = local.key_name

  # IAM role & instance profile
  # Use the existing instance profile
  create_iam_instance_profile = false
  iam_instance_profile        = local.iam_role_name_asg_instance

  user_data_base64            = base64encode(local.ec2_loadtest_user_data)
  user_data_replace_on_change = true

  enable_volume_tags = false
  root_block_device = [
    {
      volume_type           = "gp3"
      throughput            = 200
      volume_size           = local.ec2_loadtest_root_block_device_volume_size
      encrypted             = true
      delete_on_termination = true
      tags = {
        Name = "ubuntu-server-loadtest-root-block"
        Description = "System OS"
      }
    },
  ]

  # IMDSv2 Enforcement
  metadata_options = {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
    instance_metadata_tags      = "disabled"
  }

  monitoring = true

  tags = local.tags
  # Additional tags for the instance
  instance_tags = {
    NightShift  = "Enabled"
    Application = "LoadTest"
    ObjectType  = "EC2"
  }

  depends_on = [
    aws_key_pair.this,
    module.vpc
  ]
}

################################################################################
# Supporting Resources
################################################################################

# Based on source:: https://github.com/terraform-aws-modules/terraform-aws-security-group
# example # https://github.com/terraform-aws-modules/terraform-aws-security-group/blob/master/examples/complete/main.tf

# Define the security group for the Linux servers
# module "loadtest-security-group" {
#   source  = "terraform-aws-modules/security-group/aws"
#   version = ">= 5.2.0"

#   name        = "loadtest-${var.env_name_short}-sg"
#   description = "Allow incoming connections"
#   vpc_id      = module.vpc.vpc_id

#   use_name_prefix = false

#   # ingress :: Open to CIDRs blocks (rule or from_port+to_port+protocol+description)
#   ingress_with_cidr_blocks = [
#     {
#       from_port   = 22
#       to_port     = 22
#       protocol    = "tcp"
#       description = "Allow incoming SSH connections"
#       cidr_blocks = "${var.vpc_cidr}"
#     },
#     {
#       from_port   = -1
#       to_port     = -1
#       protocol    = "icmp"
#       description = "Allow incoming ICPM connections"
#       cidr_blocks = "${var.vpc_cidr}"
#     },
#     {
#       from_port   = 5671
#       to_port     = 5672
#       protocol    = "tcp"
#       description = "LoadTest Application"
#       cidr_blocks = "${var.vpc_cidr}"
#     },
#     {
#       from_port   = 15672
#       to_port     = 15672
#       protocol    = "tcp"
#       description = "LoadTest Management Console"
#       cidr_blocks = "${var.vpc_cidr}"
#     },
#   ]

#   # egress :: Open to CIDRs blocks (rule or from_port+to_port+protocol+description)
#   egress_with_cidr_blocks = [
#     {
#       from_port   = 0
#       to_port     = 0
#       protocol    = "-1"
#       description = "Allow outcoming to WWW connections"
#       cidr_blocks = "0.0.0.0/0"
#     },
#   ]

#   tags = local.tags
# }

#############################################
### Route53 - Create DNS Records ###
#############################################

# Create A record for Back-End EC2 Instance
# module "dns_record_for_loadtest_ec2" {
#   source  = "terraform-aws-modules/route53/aws//modules/records"
#   version = ">= 4.1.0"

#   zone_id = data.aws_route53_zone.this.zone_id

#   records = [
#     {
#       name = local.loadtest_ec2_subdomain
#       type = "A"
#       ttl     = 300
#       records = [
#         module.ec2-ubuntu-server-loadtest.private_ip,
#       ]
#     },
#   ]

#   depends_on = [
#     module.ec2-ubuntu-server-loadtest,
#   ]
# }
