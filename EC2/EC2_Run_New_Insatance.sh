#!/bin/bash


#Exit After Any ERROR Occured
set -e 

# Region 
REGION="us-east-1"

# AMI ID -> (OS ,Region)
AMI_ID_UBUNTU="ami-0360c520857e3138f"

# Instance Type
INSTANCE_TYPE="t2.micro"

# Key-Pair Name and Path
KEY_PAIR_NAME="devops90-cli-key"
KEY_OUTPUT_PATH="/mnt/c/Users/Dell/OneDrive/Desktop/Cloud Architectures Design/KeyPairs/devops90-cli-key.ppk"

# Security Group Name
SG_NAME="devops90-sg"

# My IP Address in CIDR
MY_IP_CIDR=$(curl -s https://checkip.amazonaws.com)/32

# Creating Key-Pair To Use It in Connecting SSH To The Machine
echo "Creating Key-Pair....⏳"

# Make Sure The Path is Already Exist
mkdir -p "$(dirname "$KEY_OUTPUT_PATH")"

aws ec2 create-key-pair \
    --key-name "$KEY_PAIR_NAME" \
    --key-format ppk \
    --region "$REGION" \
    --query 'KeyMaterial' \
    --output text > "/mnt/c/Users/Dell/OneDrive/Desktop/Cloud Architectures Design/KeyPairs/devops90-cli-key.ppk"

echo "The Key-Pair -> devops90-cli-key.ppk Created Successfully✅"


# Creating Security Group To Allow Access To Port 80 For HTTP and Port 22 For SSH From My IP
echo "Creating Security Group....⏳"

SG_ID=$(aws ec2 create-security-group \
    --group-name "$SG_NAME" \
    --description 'from cli' \
    --region "$REGION" \
    --query 'GroupId' \
    --output text)

echo "Security Group with ID -> \"$SG_ID\" Created Successfully✅"

# Adding Rule To Allow SSH Trafic on Port 22 from My IP as a Source 
aws ec2 authorize-security-group-ingress \
    --group-id "$SG_ID" \
    --protocol tcp \
    --port 22 \
    --region "$REGION" \
    --cidr "$MY_IP_CIDR" \
    > /dev/null

echo "SSH Traffic Allowed Successfully on Port 22 From Source IP -> \"$MY_IP_CIDR\" ✅"

# Adding Rule To Allow HTTP Trafic on Port 80 from My IP as a Source 
aws ec2 authorize-security-group-ingress \
    --group-id "$SG_ID" \
    --protocol tcp \
    --port 80 \
    --region "$REGION" \
    --cidr "$MY_IP_CIDR" \
    > /dev/null

echo "HTTP Traffic Allowed Successfully on Port 80 From Source IP -> \"$MY_IP_CIDR\" ✅"


echo "Creating New Instance...⏳"

# Creating New Instance With These Configurations
INSTANCE_ID=$(aws ec2 run-instances \
    --image-id "$AMI_ID_UBUNTU" \
    --count 1 \
    --instance-type "$INSTANCE_TYPE" \
    --key-name "$KEY_PAIR_NAME" \
    --region "$REGION" \
    --security-group-ids "$SG_ID" \
    --tag-specifications "ResourceType=instance,Tags=[{Key=env,Value=devops},{Key=name,Value=devops-cli}]" \
    --query 'Instances[0].InstanceId' \
    --output text)

echo "New Instance Created Successfully with ID -> \"$INSTANCE_ID\" ✅"
