#!/bin/bash
# shellcheck disable=SC2034

private_domain_name="yosef.com"
public_domain_name="zaher.online"
region="us-east-1"
vpc_name="Default_VPC"
instance_name="SERVER"

get_vpc_id()
{
    # $1 is VPC Name for VPC I Want it's ID
    
    vpc_id=$(aws ec2 describe-vpcs --filters "Name=tag:Name,Values=$1" | grep -oP '(?<="VpcId": ")[^"]*')
    
    if [ "$vpc_id" == "" ]; then
        
        echo "The VPC with Name : $vpc_name is Not Exist."
        exit 1
    fi

    echo "VPC with Name : $vpc_name is Founded and it's VpcId : $vpc_id"
}

get_instance_ip()
{
    # $1 is Name of Instance You Want to Find it's IP ,$2 (Private or Public)
    instance_ip=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=$1" Name=instance-state-name,Values=running | grep -oP "(?<=\"$2IpAddress\": \")[^\"]*" | uniq)
    
    if [ "$instance_ip" == "" ]; then
    
        echo "Instance with Name : $instance_name is Not Founded."
        exit 1
    
    fi

    echo "Instance with Name : $instance_name is Founded and it's IP : $instance_ip."
}

create_hosted_zone()
{
    # $1 (Private or Public) Hosted Zone ,$2 is VPC Region ,$3 is VPC ID
    
    time=$(date -u +"%Y-%m-%d-%H-%M-%S")

        if [ "$1" == "Public" ]; then
    
            hosted_zone_check=$(aws route53 list-hosted-zones --query "HostedZones[?Name == '$public_domain_name.']" | grep -oP '(?<="Id": ")[^"]*')

            if [ "$hosted_zone_check" == "" ]; then

                hosted_zone_id=$(aws route53 create-hosted-zone --name "$public_domain_name" \
                    --caller-reference "$time" \
                    --query HostedZone | grep -oP '(?<="Id": ")[^"]*')

                if [ "$hosted_zone_id" == "" ]; then
                    echo "Error in Creating Public Hosted Zone."
                    exit 1
                fi

                echo "Public Hosted Zone Created Successfully with id : $hosted_zone_id"

            else 

                hosted_zone_id=$hosted_zone_check
                echo "Public Hosted Zone is Already Exist With id : $hosted_zone_id" 
            
            fi
        
        else

            hosted_zone_check=$(aws route53 list-hosted-zones --query "HostedZones[?Name == '$private_domain_name.']" | grep -oP '(?<="Id": ")[^"]*')

            if [ "$hosted_zone_check" == "" ]; then

                hosted_zone_id=$(aws route53 create-hosted-zone --name "$private_domain_name" \
                                    --caller-reference "$time" \
                                    --hosted-zone-config Comment="Private Hosted Zone for Default VPC",PrivateZone=true \
                                    --vpc VPCRegion="$2",VPCId="$3" \
                                    --query HostedZone | grep -oP '(?<="Id": ")[^"]*')

                if [ "$hosted_zone_id" == "" ]; then
                    echo "Error in Creating Private Hosted Zone."
                    exit 1
                fi

                echo "Private Hosted Zone Created Successfully with id : $hosted_zone_id"

            else 

                hosted_zone_id=$hosted_zone_check
                echo "Private Hosted Zone is Already Exist With id : $hosted_zone_id" 
            
            fi            
        
        fi
}


create_record()
{
    # $1 is (Public or Private) Record ,$2 is SubDomain ,$3 is the IP
    if [ "$1" == "Public" ]; then

        full_sub_domain="$2.$public_domain_name"
        hosted_zone_id=$(aws route53 list-hosted-zones --query "HostedZones[?Name == '$public_domain_name.']" | grep -oP '(?<="Id": ")[^"]*')

    else

        full_sub_domain="$2.$private_domain_name"
        hosted_zone_id=$(aws route53 list-hosted-zones --query "HostedZones[?Name == '$private_domain_name.']" | grep -oP '(?<="Id": ")[^"]*')

    fi

    record_changes=$(cat << EOF
{
    "Comment": "Creating a new A record",
    "Changes": [
    {
        "Action": "CREATE",
        "ResourceRecordSet": {
        "Name": "$full_sub_domain",
        "Type": "A",
        "TTL": 300,
        "ResourceRecords": [
            {
            "Value": "$3"
            }
        ]
        }
    }
    ]
}
EOF
)

    change=$(echo "$record_changes" | tr -d "\n" | tr -d " ")
    
    check_record=$(aws route53 list-resource-record-sets --hosted-zone-id "$hosted_zone_id" --query "ResourceRecordSets[?Name == '$full_sub_domain.']" | grep -oP '(?<="Name": ")[^"]*')

    if [ "$check_record" == "" ]; then
    
        change_info=$(aws route53 change-resource-record-sets --hosted-zone-id "$hosted_zone_id" --change-batch "$change")
        echo "DNS Record with Name : $full_sub_domain Created Successfully."
    
    else
    
        echo "DNS Record already exist."
    
    fi
}

get_instance_ip "$instance_name" Public
create_record Public httpserver "$instance_ip"
get_instance_ip "$instance_name" Private
create_record Private srever "$instance_ip"

