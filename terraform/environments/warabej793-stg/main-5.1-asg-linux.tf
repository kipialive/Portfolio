/*
###### ###### ###### ###### ###### 
### AWS Auto Scaling Group (ASG) ###
###### ###### ###### ###### ###### 

Based on source:: https://github.com/terraform-aws-modules/terraform-aws-autoscaling
# example # https://github.com/terraform-aws-modules/terraform-aws-autoscaling/blob/master/examples/complete/main.tf

*/

locals {
  asg_name                            = "backend-${var.env_name_short}-asg"
  asg_root_block_device_volume_size   = 20
  asg_instance_type                   = "t2.small" # Change to "xxxxxxxx
  iam_role_name_asg_instance          = "backend-${var.env_name_short}-asg"

  launch_template_name                = "${local.asg_name}-template"
  launch_template_description         = "Launch template for Back-End Application"

  # Additional tags for the instance
  additional_instance_tags = {
    ObjectType = "EC2_in_ASG"
    Application = "Backend"
  }
}

data "aws_ami" "find_ami_for_asg" {
  most_recent = true

  filter {
    name   = "tag:Name"
    values = ["warabej793-stg-env-backend-al2023"]
  }

  filter {
    name   = "tag:Environment"
    values = ["${var.env_name_short}"]
  }

  filter {
    name   = "tag:DeliveryType"
    values = ["Manual"]
  }

  filter {
    name   = "tag:ObjectType"
    values = ["AMI"]
  }

  owners = ["self"] # Replace with the owner ID or use "self" if the AMI is owned by your account
}

# output "ami_id_for_asg" {
#   value = data.aws_ami.find_ami_for_asg.id
# }

#############################################################
### AWS Auto Scaling Group (ASG) for Backend Applications ###
#############################################################

module "asg" {
  source  = "terraform-aws-modules/autoscaling/aws"
  version = ">= 8.0.1" # Use the desired version of the module

  # Disable creation of the ASG and all resources
  # create = false
  # create_launch_template = false

  # Autoscaling group
  name = local.asg_name

  min_size                  = 0
  max_size                  = 2
  desired_capacity          = 2
  wait_for_capacity_timeout = 0
  health_check_type         = "EC2"
  vpc_zone_identifier       = data.aws_subnets.main_private_subnets.ids

  security_groups           = [module.linux-security-group.security_group_id]

  initial_lifecycle_hooks = [
    {
      name                  = "ExampleStartupLifeCycleHook"
      default_result        = "CONTINUE"
      heartbeat_timeout     = 60
      lifecycle_transition  = "autoscaling:EC2_INSTANCE_LAUNCHING"
      notification_metadata = jsonencode({ "hello" = "world" })
    },
    {
      name                  = "ExampleTerminationLifeCycleHook"
      default_result        = "CONTINUE"
      heartbeat_timeout     = 180
      lifecycle_transition  = "autoscaling:EC2_INSTANCE_TERMINATING"
      notification_metadata = jsonencode({ "goodbye" = "world" })
    }
  ]

  instance_refresh = {
    strategy = "Rolling"
    preferences = {
      checkpoint_delay       = 600
      checkpoint_percentages = [35, 70, 100]
      instance_warmup        = 300
      min_healthy_percentage = 50
      max_healthy_percentage = 100
    }
    triggers = ["tag"]
  }

  # Launch template
  launch_template_name                = local.launch_template_name
  launch_template_description         = local.launch_template_description
  launch_template_use_name_prefix     = false
  update_default_version              = true

  image_id          = data.aws_ami.find_ami_for_asg.id
  instance_type     = local.asg_instance_type
  # ebs_optimized     = true
  enable_monitoring = true

  key_name  = local.key_name

  # IAM role & instance profile
  create_iam_instance_profile = true
  iam_role_name               = local.iam_role_name_asg_instance
  iam_role_use_name_prefix    = false
  # iam_role_path               = "/ec2/"
  iam_role_description        = "IAM role for Backend instances in ASG"
  iam_role_tags = {
    CustomIamRole = "Yes"
    Purpose = "Backend Linux Machine"
  }
  iam_role_policies = {
    AmazonEC2RoleforSSM                 = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM"
    AmazonSSMManagedInstanceCore        = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
    CloudWatchAgentServerPolicy         = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
    warabej793-github-actions            = "arn:aws:iam::${var.aws_account_id}:policy/warabej793-github-actions"
  }

  block_device_mappings = [
    {
      # Root volume
      device_name = "/dev/xvda"
      no_device   = 0
      ebs = {
        volume_type           = "gp3"
        throughput            = 200
        volume_size           = local.asg_root_block_device_volume_size
        delete_on_termination = true
        encrypted             = true
        tags = {
          Name = "asg-root-block"
          Description = "System OS"
        }
      }
    },
  ]

  # capacity_reservation_specification = {
  #   capacity_reservation_preference = "open"
  # }

  # cpu_options = {
  #   core_count       = 1
  #   threads_per_core = 1
  # }

  # credit_specification = {
  #   cpu_credits = "standard"
  # }

  # instance_market_options = {
  #   market_type = "spot"
  #   spot_options = {
  #     block_duration_minutes = 60
  #   }
  # }

  # This will ensure imdsv2 is enabled, required, and a single hop which is aws security
  # best practices
  # See https://docs.aws.amazon.com/securityhub/latest/userguide/autoscaling-controls.html#autoscaling-4
  # IMDSv2 Enforcement
  metadata_options = {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
    instance_metadata_tags      = "disabled"
  }

  # network_interfaces = [
  #   {
  #     delete_on_termination = true
  #     description           = "eth0"
  #     device_index          = 0
  #     security_groups       = ["sg-12345678"]
  #   },
  #   {
  #     delete_on_termination = true
  #     description           = "eth1"
  #     device_index          = 1
  #     security_groups       = ["sg-12345678"]
  #   }
  # ]

  # placement = {
  #   availability_zone = "us-west-1b"
  # }

  # tag_specifications = [
  #   {
  #     resource_type = "instance"
  #     tags          = { WhatAmI = "Instance" }
  #   },
  #   {
  #     resource_type = "volume"
  #     tags          = { WhatAmI = "Volume" }
  #   },
  #   {
  #     resource_type = "spot-instances-request"
  #     tags          = { WhatAmI = "SpotInstanceRequest" }
  #   }
  # ]

  # Traffic source attachment
  traffic_source_attachments = {
    # ex-nlb = {
    #   traffic_source_identifier = module.nlb-internal-backend.target_groups["ex-target-main"].arn
    #   traffic_source_type       = "elbv2" # default
    # }
    ex-alb = {
      traffic_source_identifier = module.alb-internal-backend.target_groups["ex-target-main"].arn
      traffic_source_type       = "elbv2" # default
    }
  }

  tags = merge(local.tags, local.additional_instance_tags)
  
  autoscaling_group_tags = { 
    Application = "Backend"
    ObjectType = "EC2_in_ASG"
    Name = local.asg_name
  }

  depends_on = [module.alb-internal-backend]
}

