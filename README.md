# ☁️ AWS Infrastructure Automation Scripts

![AWS](https://img.shields.io/badge/AWS-CLI-232F3E?style=for-the-badge&logo=amazon-aws&logoColor=white)
![Bash](https://img.shields.io/badge/Shell_Script-Bash-4EAA25?style=for-the-badge&logo=gnu-bash&logoColor=white)
![Status](https://img.shields.io/badge/Status-Active-success?style=for-the-badge)

Welcome to the **AWS Infrastructure Automation** repository. This collection of Bash scripts is designed to automate the provisioning, management, and configuration of various AWS resources. Whether you are a DevOps engineer, a Cloud Architect, or a developer, these scripts provide a robust foundation for managing your cloud infrastructure efficiently using the AWS CLI.

---

## 📋 Table of Contents

- [Prerequisites](#-prerequisites)
- [Repository Structure](#-repository-structure)
- [Detailed Module Documentation](#-detailed-module-documentation)
  - [Access Control Lists (ACL)](#1-access-control-lists-acl)
  - [Elastic Block Store (EBS)](#2-elastic-block-store-ebs)
  - [Elastic Compute Cloud (EC2)](#3-elastic-compute-cloud-ec2)
  - [Elastic Load Balancing (ELB)](#4-elastic-load-balancing-elb)
  - [Route 53](#5-route-53)
  - [Simple Storage Service (S3)](#6-simple-storage-service-s3)
  - [Virtual Private Cloud (VPC)](#7-virtual-private-cloud-vpc)
- [Usage](#-usage)
- [Author](#-author)

---

## 🛠 Prerequisites

Before running these scripts, ensure you have the following installed and configured on your system:

1.  **AWS CLI**: The Amazon Web Services Command Line Interface.
    *   [Installation Guide](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
    *   Run `aws configure` to set up your credentials and default region.
2.  **jq**: A lightweight and flexible command-line JSON processor (used for parsing AWS CLI output).
    *   [Download jq](https://stedolan.github.io/jq/download/)
3.  **Bash Shell**: A Unix-like shell environment (Linux, macOS, or WSL on Windows).

---

## 📂 Repository Structure

The repository is organized by AWS service, making it easy to locate specific automation tasks.

| Folder | Service | Description |
| :--- | :--- | :--- |
| `ACL/` | **Network ACL** | Scripts for managing Network Access Control Lists and rules. |
| `EBS/` | **EBS** | Automation for creating, attaching, and testing EBS volumes. |
| `EC2/` | **EC2** | Instance provisioning, security group setup, and lifecycle management. |
| `ELB/` | **ELB** | Setup for Application Load Balancers, Target Groups, and Listeners. |
| `Route53/` | **Route 53** | DNS management, hosted zone creation, and record set updates. |
| `S3/` | **S3** | Bucket creation, object management, and security policies. |
| `VPC/` | **VPC** | Comprehensive network design including Subnets, Gateways, and Route Tables. |

---

## 📖 Detailed Module Documentation

### 1. Access Control Lists (ACL)
Located in: `ACL/`

*   **`ACL_Exercise.sh`**: A comprehensive script that:
    *   Checks for existing Network ACLs.
    *   Creates a new Custom ACL if one doesn't exist.
    *   Adds **Inbound Rules** to allow traffic from a specific IP.
    *   Adds **Outbound Rules** to allow traffic to a specific IP.
    *   Associates the ACL with a specific Subnet.

### 2. Elastic Block Store (EBS)
Located in: `EBS/`

*   **`EBS.sh`**: Automates the lifecycle of an EBS volume:
    *   Creates a high-performance `io2` volume.
    *   Waits for the volume to become available.
    *   Attaches the volume to a specific EC2 instance.
    *   Detaches and deletes the volume (cleanup).
*   **`EBS_Load_Test.sh`**: (If applicable) Script designed to perform load testing or I/O operations on attached volumes.

### 3. Elastic Compute Cloud (EC2)
Located in: `EC2/`

*   **`EC2.sh`**: The core provisioning script.
    *   **Key Pair**: Creates a secure `.ppk` key pair for SSH access.
    *   **Security Group**: Creates a firewall allowing SSH (22) and HTTP (80) access.
    *   **Launch**: Deploys an Ubuntu `t3.micro` instance with tags.
    *   **Cleanup**: Includes commands to terminate instances and delete security groups.
*   **`EC2_Run_New_Insatance.sh`**: Simplified script for launching new instances quickly.
*   **`Instance_From_LaunchTemplate.sh`**: Launches instances based on pre-defined Launch Templates for consistency.
*   **`User_Data_Script_HTTP_Service.sh`**: A startup script (User Data) that installs the **.NET 8.0 SDK**, clones a custom repository, and sets up a systemd service to run a .NET HTTP server on **port 8002**.
*   **`ApacheServer_UserData_Script.sh`**: Similar to the above, but specifically tailored for Amazon Linux (uses `dnf`), installing Apache and creating a styled HTML page with server info.

### 4. Elastic Load Balancing (ELB)
Located in: `ELB/`

*   **`ELB.sh`**: Sets up a scalable load balancing architecture.
    *   Creates an **Application Load Balancer (ALB)**.
    *   Creates a **Target Group** and registers EC2 instances.
    *   Creates a **Listener** to forward HTTP traffic from the ALB to the Target Group.

### 4.1 Auto Scaling Group (ASG)
Located in: `ASG/`

*   **`ASG.sh`**: Script for automated deployment of a complete Auto Scaling Group (ASG) architecture:
    *   Retrieves VPC, Subnet, and Security Group IDs by name.
    *   Creates a **Network Load Balancer (NLB)** and attaches it to the specified subnets and security group.
    *   Creates a **Target Group** (TCP protocol, customizable port) and links it to the NLB.
    *   Sets up a **Listener** to forward traffic from the NLB to the Target Group.
    *   Provisions an **Auto Scaling Group** using a Launch Template, attaches it to the Target Group, and configures health checks and scaling parameters (min/max/desired size).
    *   Attaches a **Target Tracking Scaling Policy** (CPU-based) to the ASG for automatic scaling.
    *   All resource names, ports, and scaling parameters are easily customizable via variables at the top of the script.
    *   Logs progress and errors for easier troubleshooting.

> **Note:** Before running, ensure all referenced resources (VPC, subnets, security group, launch template) exist and their names match the variables in the script.

### 4.2 Load Testing with k6
Located in: `k6 Load Test/`

*   **`script.js`**: Automated load testing script using [k6](https://k6.io/):
    *   Simulates traffic to the HTTP service behind the NLB (Network Load Balancer).
    *   Defines multiple stages with increasing and decreasing numbers of virtual users to test scalability and performance.
    *   Sends HTTP GET requests to the NLB endpoint (replace with your actual DNS if needed).
    *   Includes customizable sleep intervals between requests.
    *   Useful for stress-testing the Auto Scaling Group and validating scaling policies.

> **Usage:**
> 1. Install k6: https://k6.io/docs/getting-started/installation/
> 2. Run the test: `k6 run script.js`
> 3. Adjust the endpoint URL and stages as needed for your environment.

### 5. Route 53
Located in: `Route53/`

*   **`Route53.sh`**: Manages Domain Name System (DNS) configurations.
    *   **Hosted Zones**: Creates Public or Private Hosted Zones based on input.
    *   **Record Sets**: Automates the creation of `A` records to point subdomains to instance IPs.
    *   **Dynamic Updates**: Fetches instance IPs dynamically to update DNS records.

### 6. Simple Storage Service (S3)
Located in: `S3/`

*   **`S3.sh`**: A master script for S3 operations.
    *   **Bucket Management**: Creates and lists buckets.
    *   **Object Operations**: Uploads and deletes files.
    *   **Security**: Manages Public Access Blocks and Object Ownership (ACLs vs. Policies).
    *   **Policies**: Applies custom JSON policies for IP-based or Domain-based restrictions.
*   **Policy Files**:
    *   `Allow_Specific_Domain_policy.json`: Restricts access to a specific referrer domain.
    *   `Allow_Specific_ip_policy.json`: Restricts access to a specific source IP.

### 7. Virtual Private Cloud (VPC)
Located in: `VPC/`

*   **`Design_Network.sh`**: Builds a complete network topology from scratch.
    *   **VPC**: Creates a VPC with a custom CIDR block.
    *   **Subnets**: Provisions Public and Private subnets across multiple Availability Zones.
    *   **Gateways**: Sets up an Internet Gateway (IGW) for public access and a NAT Gateway for private outbound access.
    *   **Route Tables**: Creates Public and Private Route Tables, adds routes, and associates them with the respective subnets.
*   **Diagrams**: Includes `AWS_Netwok_Design.drawio` and images visualizing the network architecture.

---

## 🚀 Usage

1.  **Clone the repository**:
    ```bash
    git clone <repository-url>
    cd AWS-Bash-Scripts-infrastructure-Automation
    ```

2.  **Navigate to the desired module**:
    ```bash
    cd EC2
    ```

3.  **Make the script executable**:
    ```bash
    chmod +x EC2.sh
    ```

4.  **Run the script**:
    ```bash
    ./EC2.sh
    ```

> **Note**: Many scripts contain hardcoded IDs (e.g., `vpc-xxxx`, `subnet-xxxx`) or IP addresses for demonstration purposes. Please edit the variables at the top of each script to match your specific AWS environment before running them.

---

## ✍️ Author

**Yosef Zaher**
*   Cloud Architect & DevOps Engineer
*   Specializing in AWS Infrastructure Automation

---
*Generated with ❤️ for the Cloud Community*
