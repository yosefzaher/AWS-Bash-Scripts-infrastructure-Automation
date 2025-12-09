#!/bin/bash

# Create VPC with CIDR 192.168.0.0/20
vpc_check=$(aws ec2 describe-vpcs --filters "Name=tag:Name,Values=MyTestVpc" \
    --query 'Vpcs[0].VpcId' \
    --output text)

echo "$vpc_check"

if [ "$vpc_check" == "None" ]; then

    vpc_result=$(aws ec2 create-vpc --cidr-block 192.168.0.0/20 \
        --region us-east-1 \
        --tag-specifications ResourceType=vpc,Tags="[{Key=Name,Value=MyTestVpc}]" \
        --output json)

    echo "$vpc_result" | jq . 

    vpc_id=$(echo "$vpc_result" | jq -r '.Vpc.VpcId')
    
    if [ "$vpc_id" == "" ]; then
        echo "Error in Creating VPC."
        exit 1
    fi

    echo "$vpc_id"
    echo "VPC is Created Successfully."

else 
    echo "VPC is Already Exist."
    vpc_id=$vpc_check
    echo "$vpc_id"
fi


# Function to Create Subnets in the VPC
create_subnet()
{
    # $1 is Subnet Number (1 ,2 ,3 ,..) ,$2 is AZ (1a ,1b ,..) ,$3 The Subnet is Public or Private ,$4 is CIDR Number

    subnet_check=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=$3-Subnet-$1" \
        --query 'Subnets[0].SubnetId' \
        --output text) 

    if [ "$subnet_check" == "None" ]; then

        subnet_result=$(aws ec2 create-subnet --vpc-id "$vpc_id" \
            --cidr-block 192.168."$4".0/22 \
            --tag-specifications ResourceType=subnet,Tags="[{Key=Name,Value=$3-Subnet-$1}]" \
            --availability-zone us-east-"$2" \
            --output json)

        echo "$subnet_result" | jq .

        subnet_id=$(echo "$subnet_result" | jq -r '.Subnet.SubnetId')

        if [ "$subnet_id" == "" ]; then
            echo "Error in Creating $3-Subnet-$1."
            exit 1
        fi

        echo "$subnet_id"
        echo "$3-Subnet-$1 is Created Successfully."

    else
        echo "$3-Subnet-$1 is Already Exist."
        subnet_id=$subnet_check
        echo "$subnet_id"
    fi
}

# Create Public Subnet with CIDR 192.168.0.0/22
create_subnet 1 1a Public 0

# Create Private Subnet with CIDR 192.168.4.0/22
create_subnet 1 1b Private 4

# Create Private Subnet with CIDR 192.168.12.0/22
create_subnet 2 1a Private 12

# Create Public Subnet with CIDR 192.168.8.0/22
create_subnet 2 1b Public 8



# Create The Internet GateWay
internet_gateway_check=$(aws ec2 describe-internet-gateways --filters "Name=tag:Name,Values=igw" \
    --query 'InternetGateways[0].InternetGatewayId' \
    --output text)

if [ "$internet_gateway_check" == "None" ]; then

    internet_gateway_id=$(aws ec2 create-internet-gateway --tag-specifications ResourceType=internet-gateway,Tags="[{Key=Name,Value=igw}]" \
        --query 'InternetGateway.InternetGatewayId' \
        --output text)

    if [ "$internet_gateway_id" == "None" ]; then
        echo "Error in Creating Internet Gateway."
        exit 1 
    fi

    echo "Internet Gateway Created Successfully."
    echo "$internet_gateway_id"

else

    echo "Internet Gateway is Already Exist."
    internet_gateway_id=$internet_gateway_check
    echo "$internet_gateway_id"

fi

# Attach Internet Gateway To The VPC
internet_gateway_Attachment_check=$(aws ec2 describe-internet-gateways --filters "Name=tag:Name,Values=igw" \
    --query 'InternetGateways[0].Attachments[].State' \
    --output text)

if [ "$internet_gateway_Attachment_check" == "" ]; then

    attachment_result=$(aws ec2 attach-internet-gateway --internet-gateway-id "$internet_gateway_id" \
        --vpc-id "$vpc_id")
    
    if [ "$attachment_result" == "" ]; then
        
        echo "igw is Attached to VPC ($vpc_id) Successfully."
    
    else

        echo "Error When Attach igw to the VPC."
        exit 1

    fi

else

    echo "The igw is Already Attached to VPC ($vpc_id)."

fi


# Allocate Elastic IP Address for NAT Gateway
nat_elastic_ip_check=$(aws ec2 describe-addresses --filters "Name=tag:Name,Values=nat_ip" \
    --query 'Addresses[0].PublicIp' \
    --output text)

if [ "$nat_elastic_ip_check" == "None" ]; then

    nat_elastic_ip=$(aws ec2 allocate-address \
        --tag-specifications ResourceType=elastic-ip,Tags="[{Key=Name,Value=nat_ip}]" \
        --query 'PublicIp' \
        --output text)
    
    if [ "$nat_elastic_ip" == "None" ]; then
        echo "Error in Allocating Elastic IP."
        exit 1
    fi

    echo "Elastic IP is Allocated Successfully."
    echo "$nat_elastic_ip"
    nat_elastic_ip_allocation_id=$(aws ec2 describe-addresses --filters "Name=tag:Name,Values=nat_ip" \
    --query 'Addresses[0].AllocationId' \
    --output text)
    echo "$nat_elastic_ip_allocation_id"

else

    echo "Elastic IP is Already Allocated."
    nat_elastic_ip=$nat_elastic_ip_check
    echo "$nat_elastic_ip"
    nat_elastic_ip_allocation_id=$(aws ec2 describe-addresses --filters "Name=tag:Name,Values=nat_ip" \
    --query 'Addresses[0].AllocationId' \
    --output text)
    echo "$nat_elastic_ip_allocation_id"    

fi

# Create The NAT Gateway
nat_gateway_check=$(aws ec2 describe-nat-gateways --filter "Name=tag:Name,Values=ngw" \
    --query 'NatGateways[0].NatGatewayId' \
    --output text)

if [ "$nat_gateway_check" == "None" ]; then

    nat_gateway_result=$(aws ec2 create-nat-gateway --subnet-id "$subnet_id" \
        --allocation-id "$nat_elastic_ip_allocation_id" \
        --connectivity-type public \
        --tag-specifications ResourceType=natgateway,Tags="[{Key=Name,Value=ngw}]" \
        --output json)

    echo "$nat_gateway_result" | jq .

    nat_gateway_id=$(echo "$nat_gateway_result" | jq -r '.NatGateway.NatGatewayId')

    if [ "$nat_gateway_id" == "" ]; then

        echo "Error in Creating NAT Gateway."
        exit 1

    fi

    echo "NAT Gateway Created Successfully."
    echo "$nat_gateway_id"

else

    echo "NAT Gateway is Already Exist."
    nat_gateway_id=$nat_gateway_check
    echo "$nat_gateway_id"

fi


# Create the Route Tables
create_route_table()
{
    # $1 Route Table is Public or Private
    route_table_check=$(aws ec2 describe-route-tables --filters "Name=tag:Name,Values=$1-Route-Table" \
        --query 'RouteTables[0].RouteTableId' \
        --output text)

    echo "$route_table_check"

    if [ "$route_table_check" == "None" ]; then

        route_table_result=$(aws ec2 create-route-table --vpc-id "$vpc_id" \
            --tag-specifications ResourceType=route-table,Tags="[{Key=Name,Value=$1-Route-Table}]" \
            --output json)
            
        echo "$route_table_result" | jq .

        route_table_id=$(echo "$route_table_result" | jq -r '.RouteTable.RouteTableId')

        if [ "$route_table_id" == "" ]; then

            echo "Error in Creating $1-Route-Table."
            exit 1
        
        fi

        echo "$1-Route-Table is Created Successfully."
        echo "$route_table_id"

    else 
    
        echo "$1-Route-Table is Already Exist."
        route_table_id=$route_table_check
        echo "$route_table_id"

    fi
}

# Create The Public Route Table
create_route_table Public

# Create The Private Route Table
create_route_table Private


# Extract The id of Public-Route-Table
public_route_table_id=$(aws ec2 describe-route-tables --filters "Name=tag:Name,Values=Public-Route-Table" \
    --query 'RouteTables[0].RouteTableId' \
    --output text)

# Check The Route with Destination : 0.0.0.0/0 is Exist or not in Public-Route-Table
public_route_table_route_check=$(aws ec2 describe-route-tables --filters "Name=tag:Name,Values=Public-Route-Table" \
    --query 'RouteTables[0].Routes[1].DestinationCidrBlock' \
    --output text)

if [ "$public_route_table_route_check" == "" ]; then

    # Add Route to The Public Route Table (Destination: 0.0.0.0/0 ,Target: igw)
    create_route_publicrt_result=$(aws ec2 create-route --route-table-id "$public_route_table_id" \
        --destination-cidr-block 0.0.0.0/0 \
        --gateway-id "$internet_gateway_id" \
        --query 'Return' \
        --output text)

    if [ "$create_route_publicrt_result" == "True" ]; then

        echo "The Route is Added to Public-Route-Table Successfully."

    else

        echo "Error in Adding New Route to Public-Route-Table."
        exit 1

    fi

else

    echo "Route is Already Exist in Public-Route-Table."

fi

# Extract The id of Private-Route-Table
private_route_table_id=$(aws ec2 describe-route-tables --filters "Name=tag:Name,Values=Private-Route-Table" \
    --query 'RouteTables[0].RouteTableId' \
    --output text)


# Check The Route with Destination : 0.0.0.0/0 is Exist or not in Private-Route-Table
private_route_table_route_check=$(aws ec2 describe-route-tables --filters "Name=tag:Name,Values=Private-Route-Table" \
    --query 'RouteTables[0].Routes[1].DestinationCidrBlock' \
    --output text)

if [ "$private_route_table_route_check" == "" ]; then

    # Add Route to The Private Route Table (Destination: 0.0.0.0/0 ,Target: ngw)
    create_route_privatert_result=$(aws ec2 create-route --route-table-id "$private_route_table_id" \
        --destination-cidr-block 0.0.0.0/0 \
        --nat-gateway-id "$nat_gateway_id" \
        --query 'Return' \
        --output text)

    if [ "$create_route_privatert_result" == "True" ]; then

        echo "The Route is Added to Private-Route-Table Successfully."

    else

        echo "Error in Adding New Route to Private-Route-Table."
        exit 1

    fi

else

    echo "Route is Already Exist in Private-Route-Table."

fi

# Extract The Public-Subnet-1 id
public_subnet_1_id=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=Public-Subnet-1" \
        --query 'Subnets[0].SubnetId' \
        --output text) 

# Extract The Public-Subnet-2 id
public_subnet_2_id=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=Public-Subnet-2" \
        --query 'Subnets[0].SubnetId' \
        --output text) 

# Extract The Private-Subnet-1 id
private_subnet_1_id=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=Private-Subnet-1" \
        --query 'Subnets[0].SubnetId' \
        --output text)                

# Extract The Private-Subnet-2 id
private_subnet_2_id=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=Private-Subnet-2" \
        --query 'Subnets[0].SubnetId' \
        --output text) 

# Assotiate The Route Tables to The Subnets
aws ec2 associate-route-table --route-table-id "$public_route_table_id" \
    --subnet-id "$public_subnet_1_id" \
    --query 'AssociationId' \
    --output text 

aws ec2 associate-route-table --route-table-id "$public_route_table_id" \
    --subnet-id "$public_subnet_2_id" \
    --query 'AssociationId' \
    --output text

aws ec2 associate-route-table --route-table-id "$private_route_table_id" \
    --subnet-id "$private_subnet_1_id" \
    --query 'AssociationId' \
    --output text

aws ec2 associate-route-table --route-table-id "$private_route_table_id" \
    --subnet-id "$private_subnet_2_id" \
    --query 'AssociationId' \
    --output text



