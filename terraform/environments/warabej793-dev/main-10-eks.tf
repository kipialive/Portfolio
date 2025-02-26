/*
###### ###### ###### ###### ###### ###### ###### ###### ######
### Amazon Elastic Kubernetes Service (EKS) - K8s ###
###### ###### ###### ###### ###### ###### ###### ###### ######

Based on source:: https://github.com/terraform-aws-modules/terraform-aws-eks

# Examples
## eks_managed_node_group
https://github.com/terraform-aws-modules/terraform-aws-eks/blob/v19.15.2/examples/eks_managed_node_group/main.tf

## complete
https://github.com/terraform-aws-modules/terraform-aws-eks/blob/v19.15.2/examples/complete/main.tf

*/

locals {
  eks_cluster_name       = "${var.env_name_short}-eks-01"
  eks_cluster_version    = "1.31"
  eks_node_group_name_01 = "${var.env_name_short}-managed-ng-01"

#   argocd_chart_url      = "https://argoproj.github.io/argo-helm"
#   argocd_chart_version  = "5.46.6"
#   argocd_apps_chart_version = "1.4.1"

  additional_tags = {
    nodegroup-type = "managed"
    cluster-name   = local.eks_cluster_name
    nodegroup-name = local.eks_node_group_name_01
    # Blueprint  = local.eks_cluster_name
    # GithubRepo = "github.com/aws-ia/terraform-aws-eks-blueprints"
    ObjectType = "EKS_Node"
    Application = "Frontend"
  }
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = ">= 20.31.6"

  cluster_name                   = local.eks_cluster_name
  cluster_version                = local.eks_cluster_version

  # https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_addon
  cluster_addons = {
    coredns                = {}
    eks-pod-identity-agent = {}
    kube-proxy             = {}
    vpc-cni                = {}
  }

  # Optional
  cluster_endpoint_public_access = true
  cluster_enabled_log_types      = []

  # Optional: Adds the current caller identity as an administrator via cluster access entry
  enable_cluster_creator_admin_permissions = true

  # To disable secret encryption
  cluster_encryption_config = {}

  vpc_id                   = module.vpc.vpc_id
  subnet_ids               = module.create-private-subnets["eks-private"].private_subnets # data.aws_subnets.eks-private-subnets.ids
  # control_plane_subnet_ids = ["subnet-xyzde987", "subnet-slkjf456", "subnet-qeiru789"]

  # EKS Managed Node Group(s)
  eks_managed_node_group_defaults = {
    ami_type       = "AL2_x86_64"
    # capacity_type  = "SPOT"
    # instance_types = ["t2.small"]
    # instance_types = ["m6i.large", "m5.large", "m5n.large", "m5zn.large"]
  }

  eks_managed_node_groups = {
    managed-ng-01 = {
      # Starting on 1.30, AL2023 is the default AMI type for EKS managed node groups
      # Configured on "eks_managed_node_group_defaults" section
      # ami_type       = "AL2023_x86_64_STANDARD"
      instance_types = ["t3a.medium"]

      min_size     = 1
      max_size     = 2
      # This value is ignored after the initial creation
      # https://github.com/bryantbiggs/eks-desired-size-hack
      desired_size = 1

      metadata_options = {
        http_endpoint               = "enabled"
        http_tokens                 = "required"
        http_put_response_hop_limit = 2
        instance_metadata_tags      = "disabled"
      }

      key_name = local.key_name
  
      create_iam_role          = true
      iam_role_name            = "${local.eks_node_group_name_01}"
      iam_role_use_name_prefix = false
      iam_role_description     = "EKS managed first node group"
      iam_role_tags = {
        Purpose = "Protector of the kubelet"
      }

      iam_role_additional_policies = {
        AmazonSSMManagedInstanceCore          = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
        CloudWatchAgentServerPolicy           = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
        AWSLoadBalancerControllerIAMPolicy    = "arn:aws:iam::${var.aws_account_id}:policy/AWSLoadBalancerControllerIAMPolicy"
        # additional                            = aws_iam_policy.node_additional.arn
      }
    }
  }

  # manage_aws_auth_configmap = true
  # Note How-To: [+100] :: https://github.com/terraform-aws-modules/terraform-aws-eks/blob/a713f6f464eb579a39918f60f130a5fbb77a6b30/modules/aws-auth/README.md?plain=1#L20

  tags = merge(local.tags, local.additional_tags)
}

################################################################################
# Supporting Resources
################################################################################
# Based on example:: https://github.com/terraform-aws-modules/terraform-aws-eks/blob/master/modules/aws-auth/README.md
# The `aws-auth` ConfigMap resources have been moved to a standalone sub-module. This removes the Kubernetes provider \
# requirement from the main module and allows for the `aws-auth` ConfigMap to be managed independently of the main module.

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.eks_auth.token
}

data "aws_eks_cluster_auth" "eks_auth" {
  name = module.eks.cluster_name
}

# Configuration the aws-auth ConfigMap.
module "eks_configmap" {
  source  = "terraform-aws-modules/eks/aws//modules/aws-auth"
  version = ">= 20.31.6"

  manage_aws_auth_configmap = true

  aws_auth_roles = [
    {
      rolearn  = "arn:aws:iam::${var.aws_account_id}:role/${local.eks_node_group_name_01}"
      username = "system:node:{{EC2PrivateDNSName}}"
      groups   = ["system:bootstrappers", "system:nodes"]
    },
    {
      rolearn  = "${module.eks.cluster_iam_role_arn}"
      username = "admin"
      groups   = ["system:masters"]
    },
    {
      rolearn  = "arn:aws:iam::${var.aws_account_id}:role/warabej793-GitHubActionsRole"
      username = "github-actions"
      groups   = ["system:masters"]
    },
  ]

  aws_auth_users = [
    {
      userarn  = "arn:aws:iam::${var.aws_account_id}:user/github-actions"
      username = "admin"
      groups   = ["system:masters"]
    },
    {
      userarn  = "arn:aws:iam::${var.aws_account_id}:user/denys"
      username = "denys"
      groups   = ["system:masters"]
    },
  ]

  aws_auth_accounts = [
    "${var.aws_account_id}",
  ]

  depends_on = [
    module.eks
  ]
}