/*
###### ###### ###### ###### ###### 
### Amazon EC2 - Linux OS ###
###### ###### ###### ###### ###### 

Based on source:: https://github.com/terraform-aws-modules/terraform-aws-ec2-instance

Steps
1. Create EC2 instance ("create = true" in module "ec2-al2023)
2. Shutdown EC2 instance
3. Create from EC2 instance Amazon Machine Image (AMI) manualy

AMI Name :: warabej793-stg-env-backend-al2023
Description :: "Back-End Application | warabej793 Stg Environment | Amazon Linux 2023"

### Tags ###
Name==warabej793-stg-env-backend-al2023
Application==Backend
ObjectType==AMI
GitRepo==affico-terraform
Environment==warabej793-stg
DeliveryType==Manual
Owner==DevOps

4. Change ("create = true" in module "ec2-al2023)
5. Run 
> terraform init && terraform validate && terraform plan -out tfplan
> terraform apply "tfplan"


*/

locals {
  al2023_linux_instance_name             = "backend-${var.env_name_short}-al2023"
  al2023_root_block_device_volume_size   = 20
  al2023_instance_type                   = "t2.small" # Change to "xxxxxxxx"

  iam_role_name_al2023_instance          = "backend-${var.env_name_short}-al2023"
  al2023_user_data              = <<-EOT
    #!/bin/bash
    echo "Hello Terraform!"
    APP_FOLDER=warabej793-stg

    mkdir /$APP_FOLDER

    ### Redis-CLI ###
    sudo dnf install -y redis6
    echo 'alias redis-cli="redis6-cli"' | sudo tee -a /etc/profile
    echo 'alias redis-cli="redis6-cli"' | sudo tee -a /etc/bashrc
    source /etc/profile; source /etc/bashrc

    ### MongoDB Shell ###
    sudo tee /etc/yum.repos.d/mongodb-org-8.0.repo > /dev/null <<EOF
    ##### ##### ##### ##### ##### #####
    [mongodb-org-8.0]
    name=MongoDB Repository
    baseurl=https://repo.mongodb.org/yum/amazon/2023/mongodb-org/8.0/\$basearch/
    gpgcheck=1
    enabled=1
    gpgkey=https://www.mongodb.org/static/pgp/server-8.0.asc
    ##### ##### ##### ##### ##### #####
    EOF

    sudo dnf install -y mongodb-mongosh-shared-openssl3 jq

    ### Git ###
    sudo dnf install -y git
    ssh-keyscan github.com >> ~/.ssh/known_hosts

    ### Node.js ###
    curl -sL https://rpm.nodesource.com/setup_20.x | sudo bash -
    sudo dnf install -y nodejs

    ### PM2 (Runtime Process Manager) ###
    sudo npm install -g pm2

    ### Install CloudWatch Agent ###
    sudo dnf install -y amazon-cloudwatch-agent

    ### Test ###
    {
      echo "Redis CLI Version: $(redis6-cli --version)"
      echo "MongoDB Shell Version: $(mongosh --version)"
      echo "Git Version: $(git --version)"
      echo "Node.js Version: $(node -v)"
      echo "npm Version: $(npm -v)"
      echo "PM2 Version: $(pm2 -v | tail -n 1)"
      echo "CloudWatch Agent status: $(sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a status | jq '.status')"

    } > /$APP_FOLDER/versions.txt    
  EOT
}

# Get latest Amazon Linux 2023 AMIs with HVM virtualization and gp2 (General Purpose SSD) root volume types
data "aws_ami" "amazon_linux_2023" {
  most_recent = true

  filter {
    name   = "name"
    values = ["al2023-ami-2023*-x86_64"] # Amazon Linux 2023 AMIs
  }

  filter {
    name   = "owner-id"
    values = ["137112412989"] # Amazon's official AWS AMI owner ID
  }
}

# output "ami_id" {
#   value = data.aws_ami.amazon_linux_2023.id
# }

data "aws_subnets" "main_private_subnets" {
  filter {
    name   = "tag:Name"
    values = ["${var.prefix_private_subnet_name}-${var.suffix_subnet_name}"]
  }

  filter {
    name   = "tag:DeliveryType"
    values = ["Terraform"]
  }

  filter {
    name   = "tag:Environment"
    values = ["${var.env_name_short}"]
  }
}

data "aws_subnet" "main_private_subnet" {
  id = element(module.vpc.private_subnets, 0)
}

#####################################
### Amazon Linux 2023 for Backend ###
#####################################
## Amazon Linux 2023 AMIs with HVM virtualization and gp2 (General Purpose SSD) root volume types
## Description:: Amazon Linux 2023 comes with five years support. It provides Linux kernel 5.10 tuned for optimal performance on Amazon EC2

module "ec2-al2023" {
  source = "terraform-aws-modules/ec2-instance/aws"

  create = false

  name = local.al2023_linux_instance_name

  ami                     = data.aws_ami.amazon_linux_2023.id # uncoment this line to get latest ami version 
  # ami                    = "ami-0d16a00c70ee279b8" # Exist only in Oregon (us-west-2)
  ignore_ami_changes      = true
  
  instance_type           = local.al2023_instance_type
  availability_zone       = data.aws_subnet.main_private_subnet.availability_zone
  subnet_id               = data.aws_subnet.main_private_subnet.id
  vpc_security_group_ids  = [module.linux-security-group.security_group_id]
  #   placement_group             = aws_placement_group.web.id
  associate_public_ip_address = false
  # source_dest_check = false
  key_name = local.key_name

  # IAM role & instance profile
  create_iam_instance_profile = true
  iam_role_name               = local.iam_role_name_al2023_instance
  iam_role_use_name_prefix    = false
  iam_role_description        = "IAM role for Backend instances"
  iam_role_tags = {
    Purpose = "Backend Linux Machine"
  }
  iam_role_policies = {
    AmazonEC2RoleforSSM                 = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM"
    AmazonSSMManagedInstanceCore        = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
    CloudWatchAgentServerPolicy         = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
    ## warabej793_mongodb_atlas_ec2_policy  = aws_iam_policy.warabej793_mongodb_atlas_ec2_policy.arn
    # S3_aero-securestorage               = aws_iam_policy.S3_aero-securestorage.arn
    # warabej793_restricted_upload         = aws_iam_policy.warabej793_restricted_upload.arn
    # allowACL                            = aws_iam_policy.allowACL.arn
  }

  user_data_base64            = base64encode(local.al2023_user_data)
  user_data_replace_on_change = true

  enable_volume_tags = false
  root_block_device = [
    {
      volume_type           = "gp3"
      throughput            = 200
      volume_size           = local.al2023_root_block_device_volume_size
      encrypted             = true
      delete_on_termination = true
      tags = {
        Name        = "al2023-root-block"
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
    Application = "Backend"
    ObjectType  = "EC2"
  }

  depends_on = [
    aws_key_pair.this,
    module.vpc
  ]
}

# output "Connect_via_SSM_to_EC2_instance" {
#   value = "aws ssm start-session --target ${module.ec2-al2023.id} --region ${var.aws_region_location}"
# }

################################################################################
# Supporting Resources
################################################################################

# Based on source:: https://github.com/terraform-aws-modules/terraform-aws-security-group
# example # https://github.com/terraform-aws-modules/terraform-aws-security-group/blob/master/examples/complete/main.tf

# Define the security group for the Linux servers
module "linux-security-group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = ">= 5.2.0"

  name        = "linux-${var.env_name_short}-sg"
  description = "Allow incoming connections"
  vpc_id      = module.vpc.vpc_id

  use_name_prefix = false

  # ingress :: Open to CIDRs blocks (rule or from_port+to_port+protocol+description)
  ingress_with_cidr_blocks = [
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      description = "Allow incoming SSH connections"
      cidr_blocks = "${var.vpc_cidr}"
    },
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      description = "Allow incoming HTTP connections"
      cidr_blocks = "${var.vpc_cidr}"
    },
    {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      description = "Allow incoming HTTPS connections"
      cidr_blocks = "${var.vpc_cidr}"
    },
    {
      from_port   = -1
      to_port     = -1
      protocol    = "icmp"
      description = "Allow incoming ICPM connections"
      cidr_blocks = "${var.vpc_cidr}"
    },
    {
      from_port   = 3000
      to_port     = 3000
      protocol    = "tcp"
      description = "Backend Application"
      cidr_blocks = "${var.vpc_cidr}"
    },
  ]

  # egress :: Open to CIDRs blocks (rule or from_port+to_port+protocol+description)
  egress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      description = "Allow outcoming to WWW connections"
      cidr_blocks = "0.0.0.0/0"
    },
  ]

  tags = local.tags
}

### Uncommect only if needed ###
# ### IAM Policy for connection to Atlas MongoDB via EC2 ###
# resource "aws_iam_policy" "warabej793_mongodb_atlas_ec2_policy" {
#   name        = "warabej793-mongodb-atlas-ec2"
#   description = "IAM policy for MongoDB Atlas access via EC2"

#   policy = jsonencode({
#     Version = "2012-10-17",
#     Statement = [
#       {
#         Effect   = "Allow",
#         Action   = "sts:AssumeRole",
#         Resource = ["arn:aws:iam::${module.vpc.vpc_owner_id}:role/${local.al2023_linux_instance_name}"]
#       }
#     ]
#   })

#   tags = local.tags
# }

### Version 1 ###
### To update of existing EC2 IAM Role ###
# # Retrieve the existing policy
# data "aws_iam_role" "backend_warabej793_role" {
#   name = local.iam_role_name_al2023_instance
# }

# # Dynamically merge the new statements into the existing policy
# locals {
#   existing_policy = jsondecode(data.aws_iam_role.backend_warabej793_role.assume_role_policy)
#   new_statements = [
#     {
#       Sid       = "AllowSelfAssume",
#       Effect = "Allow",
#       Principal = {
#         AWS = "arn:aws:iam::${module.vpc.vpc_owner_id}:role/${local.al2023_linux_instance_name}"
#       },
#       Action = "sts:AssumeRole"
#     }
#   ]
# }

# resource "aws_iam_role" "backend_warabej793_role" {
#   name = local.iam_role_name_al2023_instance

#   assume_role_policy = jsonencode({
#     Version = "2012-10-17",
#     Statement = concat(local.existing_policy.Statement, local.new_statements)
#   })
# }

### Version 2 ###
### IAM Role for connection to Atlas MongoDB via EC2 ###
# resource "aws_iam_role" "warabej793_ec2_role_for_mongodb_atlas" {
#   name = local.iam_role_name_al2023_instance

#   assume_role_policy = jsonencode({
#     Version = "2012-10-17",
#     Statement = [
#       {
#         Sid       = "AllowSelfAssume",
#         Effect    = "Allow",
#         Principal = {
#           AWS = "arn:aws:iam::${module.vpc.vpc_owner_id}:role/${local.al2023_linux_instance_name}"
#         },
#         Action = "sts:AssumeRole"
#       },
#       {
#         Sid       = "AllowEC2",
#         Effect    = "Allow",
#         Principal = {
#           Service = "ec2.amazonaws.com"
#         },
#         Action = "sts:AssumeRole"
#       }
#     ]
#   })

#   depends_on = [
#     module.ec2-al2023,
#   ]
# }