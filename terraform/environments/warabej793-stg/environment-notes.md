# First run commands #

```bash
terraform init && terraform validate
terraform plan -out tfplan 
terraform apply "tfplan"

# List all installed components (include modules)
terraform state list

# Remove || Delete specific component 
terraform destroy -target module.ec2-al2023 -target module.eks

# Forcing Re-creation of Resources
> terraform state list | grep rds_mssql
    module.creates_RDS_MSSQL_DB_subnet_group.aws_db_subnet_group.this[0]
    module.rds_mssql.module.db_instance.data.aws_iam_policy_document.enhanced_monitoring
    module.rds_mssql.module.db_instance.data.aws_partition.current
    module.rds_mssql.module.db_instance.aws_db_instance.this[0]
    module.rds_mssql.module.db_instance.random_id.snapshot_identifier[0]

### Forcing Re-creation of Resources ###
> terraform apply -replace="module.rds_mssql.module.db_instance.aws_db_instance.this[0]"

# Remove all components
terraform destroy
    # !!! Very DANGEROUS !!! ### terraform destroy -auto-approve
```

# Connect to AWS EKS && Rename K8s Endpoint name to SHORT one #

```bash
# aws eks --region <region-code> update-kubeconfig --name <cluster_name>
> aws eks --region us-west-2 update-kubeconfig --name warabej793-stg-eks-01
#-# Added new context arn:aws:eks:us-west-2:379429979999:cluster/warabej793-stg-eks-01 to /Users/kipialive/.kube/config

# kubectx <NEW_NAME>=<NAME> : rename context <NAME> to <NEW_NAME>
> kubectx stg_eks_warabej793=arn:aws:eks:us-west-2:379429979999:cluster/warabej793-stg-eks-01
#-# Context "arn:aws:eks:us-west-2:379429979999:cluster/warabej793-stg-eks-01" renamed to "stg_eks_warabej793".

# List connected EKS's
> lscl

# change || connect to K8s cluster
> chcl
```

# Connect via SSM #

```bash
# EKS Node 
aws ssm start-session --target i-073ce13ba784a5188 --region us-west-2
sudo -i 

# Backend EC2 Instance
aws ssm start-session --target i-0c6207d174b79e469 --region us-west-2
sudo -i 
```

# Redis Test conncetion from EC2 Instance #

```bash
# Connect via SSM to the Backend EC2 Instance #
aws ssm start-session --target i-0c6207d174b79e469 --region us-west-2
sudo -i 

### without --tls ###
> redis-cli -c -h redis-warabej793-stg.mnaarf.0001.usw2.cache.amazonaws.com -p 6379

> ping
> exit
```

# MongoDB Shell conncetion from EC2 Instance #

```bash
### Connect to Instance via SSM "|| SSH ###
> aws ssm start-session --target i-0b34da32e11a45006 --region us-west-2
> sudo -i 

# Connection with EC2 Instance IAM Role
> mongosh "mongodb+srv://warabej793-prod.qxxbw.mongodb.net/?authSource=%24external&authMechanism=MONGODB-AWS" --apiVersion 1
```