---
<!-- #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### 
#### Auto Scaling group (EC2) #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### ####
#### #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### -->
---
You can use the AWS CLI to retrieve and modify Auto Scaling group settings.

### 1. Get Desired Capacity, Min, and Max for Auto Scaling Groups
To get the desired capacity, minimum, and maximum size of all Auto Scaling groups, run:

```sh
aws autoscaling describe-auto-scaling-groups --query "AutoScalingGroups[*].[AutoScalingGroupName, MinSize, MaxSize, DesiredCapacity]" --output table
```

```bash
------------------------------------------------------------------------------------------------------
|                                      DescribeAutoScalingGroups                                     |
+-------------------------------------------------------------------------------------+----+----+----+
|  backend-warabej793-stg-asg-20250113183520122700000001                               |  0 |  2 |  2 |
|  eks-managed-ng-01-20250109160612432100000001-46ca25e8-7abf-e3a5-cf76-49fc7858a16d  |  1 |  2 |  1 |
|  eks-managed-ng-01-20250113223559558500000014-2cca30e7-9ff5-00e6-a96e-6a81f8edf485  |  1 |  3 |  2 |
+-------------------------------------------------------------------------------------+----+----+----+
```

To scale down the Auto Scaling group **`backend-warabej793-stg-asg-20250113183520122700000001`** to zero, run the following AWS CLI command:

```sh
aws autoscaling update-auto-scaling-group \
    --auto-scaling-group-name backend-warabej793-stg-asg-20250113183520122700000001 \
    --min-size 0 \
    --max-size 0 \
    --desired-capacity 0
```

### Explanation:
- `--min-size 0`: Prevents new instances from being launched.
- `--max-size 0`: Ensures the Auto Scaling group cannot scale up.
- `--desired-capacity 0`: Immediately scales down to zero instances.

Let me know if you need any modifications! 🚀


To scale up the Auto Scaling Group **`backend-warabej793-stg-asg-20250113183520122700000001`** back to its previous configuration, you need to restore its **MinSize, MaxSize, and DesiredCapacity** values.

### **Steps to Restore Previous Configuration**

1. **First, retrieve the original settings before scaling down (if you haven't saved them yet):**  
   You already had:
   ```
   MinSize: 0
   MaxSize: 2
   DesiredCapacity: 2
   ```
   If you're unsure, you can check it again with:
   ```sh
   aws autoscaling describe-auto-scaling-groups \
       --query "AutoScalingGroups[?AutoScalingGroupName=='backend-warabej793-stg-asg-20250113183520122700000001'].[MinSize, MaxSize, DesiredCapacity]" \
       --output table
   ```

2. **Scale Up to Restore Previous Values:**
   ```sh
   aws autoscaling update-auto-scaling-group \
       --auto-scaling-group-name backend-warabej793-stg-asg-20250113183520122700000001 \
       --min-size 0 \
       --max-size 2 \
       --desired-capacity 2
   ```



### **Alternative: Store and Restore Configuration Dynamically**
If you often scale down and want to **automate restoration**, you can save the original values before scaling down:

#### **Step 1: Save Current Configuration to a File**
```sh
aws autoscaling describe-auto-scaling-groups \
    --query "AutoScalingGroups[?AutoScalingGroupName=='backend-warabej793-stg-asg-20250113183520122700000001'].[MinSize, MaxSize, DesiredCapacity]" \
    --output json > asg_config.json
```

#### **Step 2: Restore from Saved Configuration**
```sh
CONFIG=$(cat asg_config.json | jq -r '.[0] | @sh')
read MIN MAX DESIRED <<< $CONFIG

aws autoscaling update-auto-scaling-group \
    --auto-scaling-group-name backend-warabej793-stg-asg-20250113183520122700000001 \
    --min-size $MIN \
    --max-size $MAX \
    --desired-capacity $DESIRED
```

This method ensures that you **restore the exact previous state** dynamically.

---

<!-- #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### 
#### EKS #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### ####
#### #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### ####  -->
---

To determine whether your **Amazon EKS worker nodes** are **Managed Node Groups** or **Self-Managed Nodes**, use the following AWS CLI commands:

---

### **1️⃣ Check for Managed Node Groups (Recommended EKS Nodes)**
Run the following command to list Managed Node Groups in your EKS cluster:

```sh
aws eks list-nodegroups --cluster-name "warabej793-stg-eks-01"
```

👉 If the command returns a list of node groups, your cluster uses **Managed Node Groups**.

To get details of a specific node group, run:
```sh
aws eks describe-nodegroup \
    --cluster-name warabej793-stg-eks-01 \
    --nodegroup-name managed-ng-01-20250113223559558500000014 \
    --query "nodegroup.scalingConfig"
```
Check the `nodegroupName` and `scalingConfig`.

---

Since your cluster **`warabej793-stg-eks-01`** has a **Managed Node Group** (`managed-ng-01-20250113223559558500000014`), you need to scale it down using **`eks update-nodegroup-config`** instead of modifying Auto Scaling Groups directly.

---

### **Scale Down the Managed Node Group to Zero**
Run this command:
```sh
aws eks update-nodegroup-config \
    --cluster-name warabej793-stg-eks-01 \
    --nodegroup-name managed-ng-01-20250113223559558500000014 \
    --scaling-config minSize=0,maxSize=1,desiredSize=0
```

This will:
- Prevent new nodes from launching (`minSize=0`)
- Ensure the node group cannot scale up (`maxSize=1`)
- Immediately scale down to zero running instances (`desiredSize=0`)

---

### **Restore Previous Scaling Configuration**
If you need to **scale back up**, restore the previous values (e.g., MinSize=1, MaxSize=3, DesiredSize=2):

```sh
aws eks update-nodegroup-config \
    --cluster-name warabej793-stg-eks-01 \
    --nodegroup-name managed-ng-01-20250113223559558500000014 \
    --scaling-config minSize=1,maxSize=3,desiredSize=2
```

---

### **Confirm Scaling Change**
To check the current scaling configuration:
```sh
aws eks describe-nodegroup \
    --cluster-name warabej793-stg-eks-01 \
    --nodegroup-name managed-ng-01-20250113223559558500000014 \
    --query "nodegroup.scalingConfig"
```

This will return:
```json
{
    "minSize": 0,
    "maxSize": 1,
    "desiredSize": 0
}
```
(after scaling down).

