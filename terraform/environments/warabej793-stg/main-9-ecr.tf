/*
###### ###### ###### ###### ###### ###### ###### ###### ###### ######
### Amazon Elastic Container Registry (ECR) – Amazon Web Services ###
###### ###### ###### ###### ###### ###### ###### ###### ###### ######

Based on source:: https://github.com/terraform-aws-modules/terraform-aws-ecr
# example # https://github.com/terraform-aws-modules/terraform-aws-ecr/blob/master/examples/complete/main.tf

*/

################################################################################
### Private Repository ###
################################################################################

module "ecr" {
  source = "terraform-aws-modules/ecr/aws"

  repository_name = "frontend-${var.env_name_short}"

#   repository_read_write_access_arns = ["arn:aws:iam::012345678901:role/terraform"]
  repository_lifecycle_policy = jsonencode({
    rules = [
      {
        rulePriority = 1,
        description  = "Keep last 30 images",
        selection = {
          tagStatus     = "tagged",
          tagPrefixList = ["v"],
          countType     = "imageCountMoreThan",
          countNumber   = 30
        },
        action = {
          type = "expire"
        }
      }
    ]
  })

  # MUTABLE - Definition: This setting 'allows' image tags in the repository to be overwritten.
  # IMMUTABLE - Definition: This setting 'prevents' image tags in the repository from being overwritten.
  repository_image_tag_mutability = "MUTABLE" ## Tag immutability (Defaults to `IMMUTABLE`) ##
  
  repository_image_scan_on_push = "false"
  
  tags = local.tags
}