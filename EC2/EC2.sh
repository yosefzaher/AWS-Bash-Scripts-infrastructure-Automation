#!/bin/bash
# ============================================================
# 📘 AWS EC2 Automation Script - by Yosef Zaher
# Purpose:
#   Automate creating an EC2 instance, configuring SSH access,
#   setting up security rules, and cleaning up resources.
# ============================================================


# ------------------------------------------------------------
# 🧩 STEP 1: Create a Key Pair
# ------------------------------------------------------------
# We create a key pair named 'devops90-cli-key' in .ppk format (used by PuTTY).
# The private key material is saved locally in 'devops90-cli-key.ppk'
# to allow SSH authentication to the instance (no password login).
# NOTE: Keep this file safe and never share it publicly.
aws ec2 create-key-pair \
    --key-name devops90-cli-key \
    --key-format ppk \
    --query 'KeyMaterial' \
    --output text > devops90-cli-key.ppk


# ------------------------------------------------------------
# 🛡️ STEP 2: Create a Security Group
# ------------------------------------------------------------
# A security group acts like a virtual firewall controlling inbound/outbound traffic.
# Here, we create one named 'devops90-sg' with a description.
# The command outputs the Security Group ID, which we’ll use later.
aws ec2 create-security-group \
    --group-name devops90-sg \
    --description 'from cli' \
    --query 'GroupId'

# Example Output:
# sg-03edc296191a2dcb0


# ------------------------------------------------------------
# 🔓 STEP 3: Add Inbound Rules (Security Group Rules)
# ------------------------------------------------------------
# Allow SSH (port 22) access ONLY from your public IP address.
# This ensures only you can connect securely via PuTTY.
aws ec2 authorize-security-group-ingress \
    --group-id sg-03edc296191a2dcb0 \
    --protocol tcp \
    --port 22 \
    --cidr 102.57.118.81/32

# Allow HTTP (port 80) to access the web server (if installed later).
aws ec2 authorize-security-group-ingress \
    --group-id sg-03edc296191a2dcb0 \
    --protocol tcp \
    --port 80 \
    --cidr 102.57.118.81/32


# ------------------------------------------------------------
# 💻 STEP 4: Launch an EC2 Instance
# ------------------------------------------------------------
# Launch a new EC2 instance using the following parameters:
#   --image-id → AMI ID for Ubuntu 22.04 (in eu-north-1 region)
#   --instance-type → Defines hardware specs (t3.micro = free-tier eligible)
#   --key-name → The SSH key created earlier for secure access
#   --security-group-ids → Apply our custom firewall rules
#   --region → AWS region to launch the instance in
#   --tag-specifications → Add metadata tags for easy identification
aws ec2 run-instances \
    --image-id ami-09e1162c87f73958b \
    --count 1 \
    --instance-type t3.micro \
    --key-name devops90-cli-key \
    --region eu-north-1 \
    --security-group-ids sg-03edc296191a2dcb0 \
    --tag-specifications "ResourceType=instance,Tags=[{Key=env,Value=devops},{Key=name,Value=devops-cli}]"

# Example Output:
# {
#   "Instances": [
#     {
#       "InstanceId": "i-0c031f241ec7fb582",
#       "State": {"Name": "pending"},
#       ...
#     }
#   ]
# }


# ------------------------------------------------------------
# 🧹 STEP 5: Terminate the Instance (Cleanup)
# ------------------------------------------------------------
# When finished testing, terminate (delete) the running instance.
aws ec2 terminate-instances --instance-ids i-0c031f241ec7fb582


# ------------------------------------------------------------
# 🚮 STEP 6: Delete the Security Group (Optional Cleanup)
# ------------------------------------------------------------
# Delete the security group to avoid clutter or extra resources.
aws ec2 delete-security-group --group-id sg-03edc296191a2dcb0


# ============================================================
# ⚙️ Additional Notes
# ------------------------------------------------------------
# 🔑 SSH Login:
#   Use PuTTY to connect:
#     - Host Name: ubuntu@<Public-IP>
#     - Port: 22
#     - Auth: Select devops90-cli-key.ppk file
#
# 🧠 Why Security Group Rules:
#   - Port 22 → SSH access
#   - Port 80 → HTTP access
#
# 🧾 Key Pair Reminder:
#   The private key (.ppk) is used for authentication.
#   Losing it means you can’t access your instance again.
#
# ============================================================
