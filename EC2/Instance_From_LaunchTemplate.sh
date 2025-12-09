#!/bin/bash

# Describe Launch Templates in the Account
launch_template_id=$(aws ec2 describe-launch-templates --filters "Name=launch-template-name,Values=dotnet-http-service-temp" \
    --query 'LaunchTemplates[0].LaunchTemplateId' \
    --output text)

if [ "$launch_template_id" == "None" ] || [ "$launch_template_id" == "" ]; then
    
    echo "Error in Extracting Launch Template ID."
    exit 1

else

    echo "Launch Template ID: $launch_template_id."

fi

sg_check=$(aws ec2 describe-security-groups --filters "Name=tag:Name,Values=SRV_SG" \
    --query 'SecurityGroups[0].GroupId' \
    --output text)

if [ "$sg_check" == "None" ] || [ "$sg_check" == "" ]; then

    sg_id=$(aws ec2 create-security-group --group-name SRV_SG \
        --description "AlloW Http Traffic from AnyWhere and SSH from My PC." \
        --tag-specifications ResourceType=security-group,Tags="[{Key=Name,Value=SRV_SG}]" \
        --query 'GroupId' \
        --output text)

    if [ "$sg_id" == "None" ] || [ "$sg_id" == "" ]; then

        echo "Error in Creating Security Group."
        exit 1

    else

        echo "Security Group Created Successfully." 
        echo "$sg_id"

        echo "Adding Rule to Allow HTTP from AnyWhere on Port 8002"
        aws ec2 authorize-security-group-ingress --group-id "$sg_id" \
            --ip-permissions IpProtocol=tcp,FromPort=8002,ToPort=8002,IpRanges='[{CidrIp=0.0.0.0/0,Description="Allow HTTP from AnyWhere"}]' \
            --output json | jq .
        
        echo "Adding Rule to Allow SSH from office IP on Port 22"
        aws ec2 authorize-security-group-ingress --group-id "$sg_id" \
            --ip-permissions IpProtocol=tcp,FromPort=22,ToPort=22,IpRanges='[{CidrIp=156.197.175.224/32,Description="Allow SSH from office IP"}]' \
            --output json | jq .

    fi

else

    echo "Security Group is Already Exist."
    sg_id=$sg_check
    echo "$sg_id"

fi

instance_check=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=SRVER0" \
    --query 'Reservations[0].Instances[0].InstanceId' \
    --output text)

if [ "$instance_check" == "None" ] || [ "$instance_check" == "" ]; then
    
    instance_result=$(aws ec2 run-instances --launch-template "LaunchTemplateId=$launch_template_id" \
        --tag-specifications ResourceType=instance,Tags="[{Key=Name,Value=SRVER0}]" \
        --security-group-ids "$sg_id" \
        --output json)

    echo "$instance_result" | jq .

    instance_id=$(echo "$instance_result" | jq -r '.Reservations[0].Instances[0].InstanceId')

    if [ "$instance_id" == "" ] || [ "$instance_id" == "None" ]; then
    
        echo "Error in Creating the Instance."
        exit 1
    
    fi

    echo "Instance is Created Successfully."

else

    echo "Instance is Already Exist."
    instance_id=$instance_check
    echo "$instance_id"

fi

instance_public_ip=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=SRVER0" \
    --query 'Reservations[0].Instances[0].PublicIpAddress' \
    --output text)

if [ "$instance_public_ip" == "" ] || [ "$instance_public_ip" == "None" ]; then
    
    echo "Error in Extracting Public IP Address."
    exit 1

else

    echo "Public IP : $instance_public_ip."

fi