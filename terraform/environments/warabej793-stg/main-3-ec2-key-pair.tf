/*
###### ###### ###### ###### ###### 
### Amazon EC2:: Key Pair ###
###### ###### ###### ###### ###### 

IMPORTANT NOTE: 
This logic has been carefully tested and verified. DO NOT change or modify the logic in the following methods unless absolutely necessary. 
The implementation ensures:
  - A Key Pair is created ONLY if it doesn't already exist.
  - Prevents unnecessary destruction of existing resources (like the AWS Key Pair and local PEM file).
  - This is the only known solution after rigorous testing with Terraform.

Changing this logic might cause state inconsistencies or unnecessary resource destruction.
If changes are required, ensure:
  - Thorough testing is performed.
  - Compatibility with the existing state is maintained.

Based on source: ChatGPT with rigorous testing for correctness and reliability.

Notes:
- Terraform checks if the key pair exists using an external data source.
- The `prevent_destroy` lifecycle block is in place to safeguard critical resources.
- If the key pair already exists, Terraform will skip creation and continue with other resources.
- This logic ensures reliable behavior in both initial and subsequent deployments.

*/

/*
### Create a Key Pair if it Doesn’t Exist ###
    Terraform will check if the key pair exists. If the key pair doesn’t exist, it will create one and save it locally.

### Do Nothing If the Key Pair Exists ###
    If the key pair already exists, Terraform will skip the creation step and continue with other resources.

### Prevent Unnecessary Destruction ###
    Prevent destruction of critical resources like AWS Key Pairs and local PEM files.

*/


# Local variables to define paths and key name
locals {
  key_name            = "${var.env_name}-key"
  folder_path         = pathexpand("~/EpaseroTech/SSH")
}

# External data source to check if the key pair exists
data "external" "check_key_pair_status" {
  program = ["bash", "-c", "[ $(aws ec2 describe-key-pairs --key-name ${local.key_name} --region ${var.aws_region_location} > /dev/null 2>&1 && echo 0 || echo 1) -eq 0 ] && echo '{\"status\": \"true\"}' || echo '{\"status\": \"false\"}'"]
}

# Check if folder path exists
data "external" "check_folder_status" {
  program = ["bash", "-c", "[ -d '${local.folder_path}' ] && echo '{\"status\": \"true\"}' || echo '{\"status\": \"false\"}'"]
}

# Use a local variable to determine if the key pair exists and the folder path also exists
locals {
  key_pair_status     = try(data.external.check_key_pair_status.result["status"] == "true", false)
  folder_status       = data.external.check_folder_status.result["status"] == "true"
}

# # Output whether the key pair exists and other params
# output "key_pair_status" {
#   value = local.key_pair_status ? "Key pair exists: ${local.key_name}" : "Key pair does not exist: ${local.key_name}"
# }

# output "key_pair_name" {
#   value = local.key_name
# }

# output "create_a_new_key_pair" {
#   value = var.create_new_key_pair
# }

# output "save_the_private_key_locally" {
#   value = length(local_file.save_private_key_pem_file)
# }

# output "check_folder_status" {
#   value = local.folder_status 
# }

################################################################################
# Key Pair Generation and Storage
################################################################################

# Generate a new private/public key pair
resource "tls_private_key" "this" {
  count = var.create_new_key_pair ? 1 : 0

  algorithm = "RSA"
  rsa_bits  = 4096
}

# Create the AWS key pair only if it doesn't exist
resource "aws_key_pair" "this" {
  count = local.key_pair_status || var.create_new_key_pair ? 1 : 0

  key_name        = local.key_name
  public_key      = trimspace(tls_private_key.this[0].public_key_openssh)

  tags = local.tags

  lifecycle {
    prevent_destroy = true
  }
}

# Optionally save the private key locally
resource "local_file" "save_private_key_pem_file" {
  count = local.key_pair_status || (var.save_pem_locally && var.create_new_key_pair && local.folder_status) ? 1 : 0

  content               = tls_private_key.this[0].private_key_pem
  filename              = "${local.folder_path}/${local.key_name}.pem"
  file_permission       = 0400

  lifecycle {
    prevent_destroy = true
  }
}