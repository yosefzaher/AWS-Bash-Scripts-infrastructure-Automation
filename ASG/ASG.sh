#!/bin/bash

VPC_NAME='MyTestVpc'
SUBNET1_NAME='Public-Subnet-1'
SUBNET2_NAME='Public-Subnet-2'
SECURITY_GROUP_NAME='NLB-SG'
REGION='us-east-1'
ELB_NAME='ASG-NLB'
ELB_TYPE='network'
TG_NAME='ASG-TG'
TG_PROTOCOL='TCP'
LS_PROTOCOL='TCP'
ASG_NAME='ASG'
LAUNCH_TEMPLATE_NAME='dotnet-http-service-temp'
ASG_HEALTH_CHECK_TYPE='ELB'
POLICY_NAME='cpu50-target-tracking-scaling-policy'
POLICY_TYPE='TargetTrackingScaling'
declare -i TG_PORT=8002
declare -i LS_PORT=80
declare -i ASG_HEALTH_CHECK_GRACE_PERIOD=120
declare -i ASG_MAX_SIZE=7
declare -i ASG_MIN_SIZE=2
declare -i ASG_DESIRED_SIZE=2

log()
{
    # $1 is the Log Message
    echo "[INFO] $1" >&2 
}

err()
{
    # $1 is the Error Message
    echo "[ERROR] $1" >&2 
}

# Get VPC ID
get_vpc_id()
{
    # $1 is the VPC Name
    local vpc_name="$1"
    local vpc_id
    
    vpc_id=$(aws ec2 describe-vpcs --filters "Name=tag:Name,Values=$vpc_name" --query 'Vpcs[].VpcId' --output text)
    
    if [ "$vpc_id" == "" ] || [ "$vpc_id" == "None" ]; then
        err "VPC with Name $vpc_name is not Exist"
        exit 1
    fi

    log "VPC with Name $vpc_name is Founded Successfully with ID : $vpc_id"
    echo "$vpc_id"
}

# Get Subnets IDs
get_subnet_id()
{
    # $1 is the Name of Subnet 1 ,$2 is the Name of Subnet 2
    local subne1_name="$1"
    local subne2_name="$2"
    local subnet1_id
    local subnet2_id
    local subnets_ids

    subnet1_id=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=$subne1_name" --query 'Subnets[].SubnetId' --output text)
    
    if [ "$subnet1_id" == "" ] || [ "$subnet1_id" == "None" ]; then
        err "Subnet with Name $subne1_name is not Exist"
        exit 1        
    fi

    log "VPC with Name $subne1_name is Founded Successfully with ID : $subnet1_id"

    subnet2_id=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=$subne2_name" --query 'Subnets[].SubnetId' --output text)
    
    if [ "$subnet2_id" == "" ] || [ "$subnet2_id" == "None" ]; then
        err "Subnet with Name $subne2_name is not Exist"
        exit 1        
    fi

    log "VPC with Name $subne2_name is Founded Successfully with ID : $subnet2_id"

    subnets_ids="$subnet1_id $subnet2_id"

    echo "$subnets_ids"
}

# Get Security Group ID (ELB)
get_sg_id()
{
    # $1 is the Security Group Name
    local sg_name="$1"
    local sg_id

    sg_id=$(aws ec2 describe-security-groups --filters "Name=tag:Name,Values=$sg_name" --query 'SecurityGroups[].GroupId' --output text)

    if [ "$sg_id" == "" ] || [ "$sg_id" == "None" ];then
        err "Security Group with Name $sg_name is not Exist"
        exit 1         
    fi

    log "Security Group with Name $sg_name is Founded Successfully with ID : $sg_id"  
    echo "$sg_id"  
}

# Create Load Balancer
create_elb()
{
    # $1 the Name of the ELB ,$2 the Type of ELB (network,application,gateway) ,$3 are the Subnets IDs ,#4 is the Security Group ID ,#5 is the Region
    local elb_name="$1"
    local elc_type="$2"
    local subnets_ids="$3"
    local subnet1_id="${subnets_ids[0]}"
    local subnet2_id="${subnets_ids[1]}"
    local elb_sg_id="$4"
    local region="$5"
    local elb_check
    local nlb_arn


    elb_check=$(aws elbv2 describe-load-balancers --region "$region" --query "LoadBalancers[?LoadBalancerName == '$elb_name']" \
                    | grep -oP '(?<="LoadBalancerArn": ")[^"]*')

    if [ "$elb_check" == "" ] || [ "$elb_check" == "None" ]; then
        
        nlb_arn=$(aws elbv2 create-load-balancer --name "$elb_name" \
                            --type "$elc_type" \
                            --subnets $subnets_ids \
                            --region "$region" \
                            --security-groups "$elb_sg_id" \
                            --query 'LoadBalancers[0].LoadBalancerArn' \
                            --output text)

        if [ "$nlb_arn" == "" ] || [ "$nlb_arn" == "None" ]; then
            err "Error in Creating Network Load Balancer With Name : $elb_name"
            exit 1
        fi

        log "Network Load Balancer Created Successfully with ARN : $nlb_arn"

    else

        nlb_arn=$elb_check
        log "Network Load Balancer is Already Exist with ARN : $nlb_arn" 

    fi

    echo "$nlb_arn"  
}

# Create Target Group
create_target_group()
{
    # $1 is the Target Group Name ,$2 is the Protocol (HTTP,HTTPS,TCP) ,$3 is the Port Number in Target Group ,$4 is the VPC ID ,$5 is the Region
    local tg_name=$1
    local tg_protocol=$2
    local tg_port=$3
    local vpc_id=$4
    local region=$5
    local tg_check
    local tg_arn
    local health_check_protocol='HTTP'

    tg_check=$(aws elbv2 describe-target-groups --region "$region" --query "TargetGroups[?TargetGroupName == '$tg_name']" | grep -oP '(?<="TargetGroupArn": ")[^"]*')

    if [ "$tg_check" == "" ] || [ "$tg_check" == "None" ]; then
        
        tg_arn=$(aws elbv2 create-target-group --name "$tg_name" \
                    --protocol "$tg_protocol" \
                    --port "$tg_port" \
                    --vpc-id "$vpc_id" \
                    --health-check-protocol "$health_check_protocol" \
                    --health-check-port "$tg_port" \
                    --target-type instance \
                    --region "$region" \
                    --query 'TargetGroups[0].TargetGroupArn' \
                    --output text)

        if [ "$tg_arn" == "" ] || [ "$tg_arn" == "None" ]; then
            err "Error in Creating Target Group With Name : $tg_name"
            exit 1
        fi

        log "Target Group Created Successfully with ARN : $tg_arn"
         
    else
        tg_arn=$tg_check
        log "Target Group is Already Exist with ARN : $tg_arn" 
    fi
    
    echo "$tg_arn"
}

# Create Listener for ELB
create_listener()
{
    # $1 is ELB ARN ,$2 is the Protocol (HTTP,HTTPS,TCP) ,$3 is the Port Number ,$4 is the Target Group ARN
    local elb_arn=$1
    local ls_protocol=$2
    local ls_port=$3
    local tg_arn=$4

    ls_arn=$(aws elbv2 create-listener --load-balancer-arn "$elb_arn" --protocol "$ls_protocol" --port "$ls_port" --default-actions Type=forward,TargetGroupArn="$tg_arn" | grep -oP '(?<="ListenerArn": ")[^"]*')

    if [ "$ls_arn" == "" ]; then
        err "Error in Creating Listener"
        exit 1        
    fi

    log "Listener is Created Successfully with ARN : $ls_arn"
    echo "$ls_arn"
}

# Create Auto-Scalling Group
create_asg()
{
    # $1 is the Name of ASG ,$2 is the Region ,$3 is Launch Template Name ,$4 is the Target Group ARN ,$5 is Health Check Type (ELB,EBS,EC2)
    # $6 is Health Check Grace Period ,$7 is Min Size ,$8 is Max Size ,$9 Desired Capacity ,$10 is the Vpc Zone Identifier (Subnets IDs)
    local asg_name=$1
    local region=$2
    local launch_template_name=$3
    local tg_arn=$4
    local health_check_type=$5
    local health_check_grace_period=$6
    local min_size=$7
    local max_size=$8
    local desired_size=$9
    local subnets_ids=(${10})
    local subnet1_id="${subnets_ids[0]}"
    local subnet2_id="${subnets_ids[1]}"
    local subnets_ids_with_comma="$subnet1_id,$subnet2_id"
    local check_asg
    local asg_arn
    local check_asg_creation

    check_asg=$(aws autoscaling describe-auto-scaling-groups --region "$region" --query "AutoScalingGroups[?AutoScalingGroupName == '$asg_name']" | grep -oP '(?<="AutoScalingGroupARN": ")[^"]*')

    if [ "$check_asg" == "" ] || [ "$check_asg" == "None" ]; then 
        
        aws autoscaling create-auto-scaling-group \
            --auto-scaling-group-name "$asg_name" \
            --launch-template LaunchTemplateName="$launch_template_name" \
            --target-group-arns "$tg_arn" \
            --health-check-type "$health_check_type" \
            --health-check-grace-period "$health_check_grace_period" \
            --min-size "$min_size" \
            --desired-capacity "$desired_size" \
            --max-size "$max_size" \
            --vpc-zone-identifier "$subnets_ids_with_comma"

        check_asg_creation=$(aws autoscaling describe-auto-scaling-groups --region "$region" --query "AutoScalingGroups[?AutoScalingGroupName == '$asg_name']" | grep -oP '(?<="AutoScalingGroupARN": ")[^"]*')
        
        if [ "$check_asg_creation" == "" ] || [ "$check_asg_creation" == "None" ]; then 
            err "Error in Creating ASG"
            exit 1 
        fi

        asg_arn=$check_asg_creation
        echo "ASG Creation Done ,Kinldy Check it from the AWS Console!"

    else

        asg_arn=$check_asg
        log "ASG with Name $asg_name is Already Exist with ARN : $asg_arn"
    
    fi
    
    echo "$asg_arn"
}

# Attach Auto-Scalling Policy
attach_asg_policy()
{
    # $1 is ASG Name ,$2 is Policy Name ,$3 is Policy Type (TargetTrackingScaling,StepScaling,SimpleScaling,PredictiveScaling)
    local asg_name=$1
    local policy_name=$2
    local policy_type=$3
    local config



    config=$(cat << EOF
{
    "TargetValue": 50,
    "PredefinedMetricSpecification": {
         "PredefinedMetricType": "ASGAverageCPUUtilization"
    }
}
EOF
)
    config=$( echo $config | tr -d '\n' | tr -d ' ')

    aws autoscaling put-scaling-policy --auto-scaling-group-name "$asg_name" \
                    --policy-name "$policy_name" \
                    --policy-type "$policy_type" \
                    --target-tracking-configuration $config  

    log "Policy Puted Successfully"
}

VPC_ID=$(get_vpc_id "$VPC_NAME")
SUBNETS_IDS=$(get_subnet_id "$SUBNET1_NAME" "$SUBNET2_NAME")
ELB_SG_ID=$(get_sg_id "$SECURITY_GROUP_NAME")

ELB_ARN=$(create_elb "$ELB_NAME" "$ELB_TYPE" "$SUBNETS_IDS" "$ELB_SG_ID" "$REGION")

TG_ARN=$(create_target_group "$TG_NAME" "$TG_PROTOCOL" "$TG_PORT" "$VPC_ID" "$REGION")

LS_ARN=$(create_listener "$ELB_ARN" "$LS_PROTOCOL" "$LS_PORT" "$TG_ARN")

ASG_ARN=$(create_asg "$ASG_NAME" "$REGION" "$LAUNCH_TEMPLATE_NAME" "$TG_ARN" "$ASG_HEALTH_CHECK_TYPE" "$ASG_HEALTH_CHECK_GRACE_PERIOD" "$ASG_MIN_SIZE" "$ASG_MAX_SIZE" "$ASG_DESIRED_SIZE" "$SUBNETS_IDS")

POLICY_DATA=$(attach_asg_policy "$ASG_NAME" "$POLICY_NAME" "$POLICY_TYPE")