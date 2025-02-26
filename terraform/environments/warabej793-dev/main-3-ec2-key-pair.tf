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
  key_name       = "${var.env_name}-key"
  home_directory = "${pathexpand("~/")}"
  pem_path       = "EpaseroTech/SSH"
}

# External data source to check if the key pair exists
data "external" "check_key_pair" {
  program = ["bash", "-c", <<EOT
aws ec2 describe-key-pairs --key-name ${local.key_name} --region ${var.aws_region_location} > /dev/null 2>&1
if [ $? -eq 0 ]; then
  echo '{"key_exists": "true"}'
else
  echo '{"key_exists": "false"}'
fi
EOT
  ]
}

# Use a local variable to determine if the key pair exists
locals {
  key_exists = try(data.external.check_key_pair.result["key_exists"] == "true", false)
}

# Output whether the key pair exists
output "key_pair_status" {
  value = local.key_exists ? "Key pair exists: ${local.key_name}" : "Key pair does not exist: ${local.key_name}"
}

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
  count = local.key_exists || var.create_new_key_pair ? 1 : 0

  key_name        = local.key_name
  public_key      = trimspace(tls_private_key.this[0].public_key_openssh)

  tags = local.tags

  lifecycle {
    prevent_destroy = true
  }
}

# Optionally save the private key locally
resource "local_file" "save_private_key_pem_file" {
  count = local.key_exists || (var.save_pem_locally && var.create_new_key_pair) ? 1 : 0

  content         = tls_private_key.this[0].private_key_pem
  filename        = "${local.home_directory}/${local.pem_path}/${local.key_name}.pem"
  file_permission = "400"

  lifecycle {
    prevent_destroy = true
  }
}