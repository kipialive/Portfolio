# Portfolio
My portfolio of work includes Terraform, CloudFormation, GitHub Actions, and many others.


# Git Repository warabej793-terraform

# Terraform AWS Infrastructure

This repository contains Terraform manifests to manage AWS infrastructure for **Development**, **Staging**, and **Production** environments. Each environment is fully isolated and stored in its own dedicated folder. The deployment process is designed to follow best practices and ensure consistency across environments.

---

## Repository Structure
```bash
.
├── environments/
│   ├── warabej793-dev/
│   │   ├── main.tf         # Terraform configuration for Development
│   │   ├── variables.tf    # Input variables for Development
│   │   ├── outputs.tf      # Outputs for Development
│   │   ├── backend.tf      # Remote state configuration for Development
│   │   └── terraform.tfvars # Optional: environment-specific variables
│   ├── warabej793-stg/
│   │   ├── main.tf         # Terraform configuration for Staging
│   │   ├── variables.tf    # Input variables for Staging
│   │   ├── outputs.tf      # Outputs for Staging
│   │   ├── backend.tf      # Remote state configuration for Staging
│   │   └── terraform.tfvars # Optional: environment-specific variables
│   ├── warabej793-prod/
│   │   ├── main.tf         # Terraform configuration for Production
│   │   ├── variables.tf    # Input variables for Production
│   │   ├── outputs.tf      # Outputs for Production
│   │   ├── backend.tf      # Remote state configuration for Production
│   │   └── terraform.tfvars # Optional: environment-specific variables
├── modules/
│   ├── network/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── vpc-peering-connection/
└── README.md
```
  * `environments` - Contains Terraform environments e.g. Development, Staging, Production.

  * `modules` - Contains reusable small Terraform modules that can be used in
  many Terraform environments.
  Those modules wrap Terraform resources and datasources and provide
  configurable variables.
  All of those modules are fully compatible with the Selectel VPC service.

---

## Key Notes

### 1. **Manual Creation of S3 Buckets for Terraform State**

Terraform requires a backend to store the state files for each environment. You must **manually create S3 buckets** for state management **before initializing Terraform**. Use the following naming convention:

- **Development**: `terraform-state-warabej793-dev`
- **Staging**: `terraform-state-warabej793-stg`
- **Production**: `terraform-state-warabej793-prod`

### Region Oregon (us-west-2)
- **Region**: `us-west-2`

#### Example: Create an S3 Bucket Using AWS CLI
```bash
### Create S3 Buckets via script file ###
vim ./create_buckets.sh
chmod +x create_buckets.sh
./create_buckets.sh
```

```bash
export REGION="us-west-2"

# Define environments and their suffixes as two parallel arrays
environments=("Stg" "Dev")
suffixes=("warabej793-stg" "warabej793-dev")

# Loop through the environments
for i in "${!environments[@]}"; do
    env="${environments[$i]}"
    Sufix="${suffixes[$i]}"
    bucket_name="terraform-state-${Sufix}"

    echo "Creating bucket: $bucket_name for environment: $env"

    # Create the bucket
    aws s3api create-bucket \
        --bucket "$bucket_name" \
        --region "$REGION" \
        --create-bucket-configuration LocationConstraint="$REGION"

    # Enable versioning on the bucket
    echo "Enabling versioning for bucket: $bucket_name"
    aws s3api put-bucket-versioning \
        --bucket "$bucket_name" \
        --region "$REGION" \
        --versioning-configuration Status=Enabled

    # Add tags to the bucket
    echo "Adding tags to bucket: $bucket_name"
    aws s3api put-bucket-tagging \
        --bucket "$bucket_name" \
        --region "$REGION" \
        --tagging "TagSet=[{Key=DeliveryType,Value=Manual_For_Terraform},{Key=Environment,Value=$env},{Key=ObjectType,Value=S3}]"

    echo "Bucket $bucket_name successfully created and configured!"
    echo "---------------------------------------------"
done

#### For Prod ROC Environment ####

export REGION="us-west-1"

# Define environments and their suffixes as two parallel arrays
environments=("Prod")
suffixes=("warabej793-prod")

# Loop through the environments
for i in "${!environments[@]}"; do
    env="${environments[$i]}"
    Sufix="${suffixes[$i]}"
    bucket_name="terraform-state-${Sufix}"

    echo "Creating bucket: $bucket_name for environment: $env"

    # Create the bucket
    aws s3api create-bucket \
        --bucket "$bucket_name" \
        --region "$REGION" \
        --create-bucket-configuration LocationConstraint="$REGION"

    # Enable versioning on the bucket
    echo "Enabling versioning for bucket: $bucket_name"
    aws s3api put-bucket-versioning \
        --bucket "$bucket_name" \
        --region "$REGION" \
        --versioning-configuration Status=Enabled

    # Add tags to the bucket
    echo "Adding tags to bucket: $bucket_name"
    aws s3api put-bucket-tagging \
        --bucket "$bucket_name" \
        --region "$REGION" \
        --tagging "TagSet=[{Key=DeliveryType,Value=Manual_For_Terraform},{Key=Environment,Value=$env},{Key=ObjectType,Value=S3}]"

    echo "Bucket $bucket_name successfully created and configured!"
    echo "---------------------------------------------"
done


#### For Prod ROC Environment ####

export REGION="us-west-2"

# Define environments and their suffixes as two parallel arrays
environments=("Prod")
suffixes=("warabej793-prod")

# Loop through the environments
for i in "${!environments[@]}"; do
    env="${environments[$i]}"
    Sufix="${suffixes[$i]}"
    bucket_name="terraform-state-${Sufix}"

    echo "Creating bucket: $bucket_name for environment: $env"

    # Create the bucket
    aws s3api create-bucket \
        --bucket "$bucket_name" \
        --region "$REGION" \
        --create-bucket-configuration LocationConstraint="$REGION"

    # Enable versioning on the bucket
    echo "Enabling versioning for bucket: $bucket_name"
    aws s3api put-bucket-versioning \
        --bucket "$bucket_name" \
        --region "$REGION" \
        --versioning-configuration Status=Enabled

    # Add tags to the bucket
    echo "Adding tags to bucket: $bucket_name"
    aws s3api put-bucket-tagging \
        --bucket "$bucket_name" \
        --region "$REGION" \
        --tagging "TagSet=[{Key=DeliveryType,Value=Manual_For_Terraform},{Key=Environment,Value=$env},{Key=ObjectType,Value=S3}]"

    echo "Bucket $bucket_name successfully created and configured!"
    echo "---------------------------------------------"
done
```