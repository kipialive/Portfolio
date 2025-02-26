aws_account_id = "379429979999"

### Oregon (us-west-2)
aws_region_location = "us-west-2" 

vpc_name = "warabej793 Dev Environment"

env_name       = "warabej793-dev-env"
env_name_short = "warabej793-dev"

### VPC CIDR blocks/range ###
# Note: Main subnet for EC2 instances
vpc_cidr                        = "10.101.0.0/16"
main-vpc-public-cidr            = "10.101.1.0/24"
main-vpc-private-cidr           = "10.101.101.0/24"

### EKS CIDR blocks/range ###
eks-subnet-01-public-cidr       = "10.101.10.0/24"
eks-subnet-02-public-cidr       = "10.101.11.0/24"
eks-subnet-03-public-cidr       = "10.101.12.0/24"

eks-subnet-01-private-cidr      = "10.101.110.0/24"
eks-subnet-02-private-cidr      = "10.101.111.0/24"
eks-subnet-03-private-cidr      = "10.101.112.0/24"

### Redis and DB's CIDR blocks/range ###
redis-subnet-01-private-cidr    = "10.101.120.0/24"
redis-subnet-02-private-cidr    = "10.101.121.0/24"

### Key Pair ###
# save_pem_locally = true