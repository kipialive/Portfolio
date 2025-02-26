aws_account_id = "379429979999"

### Oregon (us-west-2)
aws_region_location = "us-west-2" 

vpc_name = "warabej793 Stg Environment"

env_name       = "warabej793-stg-env"
env_name_short = "warabej793-stg"

### VPC CIDR blocks/range ###
# Note: Main subnet for EC2 instances
vpc_cidr                        = "10.151.0.0/16"
main-vpc-public-cidr            = ["10.151.1.0/24"]
main-vpc-private-cidr           = ["10.151.101.0/24", "10.151.102.0/24"]

### EKS CIDR blocks/range ###
eks-subnet-01-public-cidr       = "10.151.10.0/24"
eks-subnet-02-public-cidr       = "10.151.11.0/24"
eks-subnet-03-public-cidr       = "10.151.12.0/24"

eks-subnet-01-private-cidr      = "10.151.110.0/24"
eks-subnet-02-private-cidr      = "10.151.111.0/24"
eks-subnet-03-private-cidr      = "10.151.112.0/24"

### Redis and DB's CIDR blocks/range ###
redis-subnet-01-private-cidr    = "10.151.120.0/24"
redis-subnet-02-private-cidr    = "10.151.121.0/24"

### Key Pair ###
# save_pem_locally = true