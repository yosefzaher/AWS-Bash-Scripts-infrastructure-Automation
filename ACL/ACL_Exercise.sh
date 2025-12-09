#!/bin/bash

default_vpc_id="vpc-063065df4192af86a"
subnet_id="subnet-0b53d6d2866d089fa"
my_ip="156.197.175.224"
network_acl_association_id="aclassoc-0f8c3f3f270fb9587"

acl_check=$(aws ec2 describe-network-acls --filters "Name=tag:Name,Values=MyACL" \
    --query 'NetworkAcls[0].NetworkAclId' \
    --output text)

if [ "$acl_check" == "None" ]; then

    acl_result=$(aws ec2 create-network-acl --vpc-id "$default_vpc_id" \
        --tag-specifications ResourceType=network-acl,Tags="[{Key=Name,Value=MyACL}]" \
        --output json)

    echo "$acl_result" | jq .

    acl_id=$(echo "$acl_result" | jq -r '.NetworkAcl.NetworkAclId')

    if [ "$acl_id" == "" ]; then
        
        echo "ERROR in Creating ACL."
        exit 1
    
    fi

    echo "ACL is Created Successfully." 
    echo "$acl_id"

else

    echo "ACL is Already Exist."
    acl_id=$acl_check
    echo "$acl_id"

fi

# Add inbound Rule To Allow Traffic Only from My PC
aws ec2 create-network-acl-entry --network-acl-id "$acl_id" \
    --ingress \
    --rule-number 100 \
    --protocol -1 \
    --rule-action allow \
    --cidr-block "$my_ip/32"

echo "inbound Rule Added Successfully."    

# Add outbound Rule To Allow Traffic Only to My PC
aws ec2 create-network-acl-entry --network-acl-id "$acl_id" \
    --egress \
    --rule-number 100 \
    --protocol -1 \
    --rule-action allow \
    --cidr-block "$my_ip/32"

echo "outbound Rule Added Successfully."    

acl_association_check=$(aws ec2 describe-network-acls --filters "Name=tag:Name,Values=MyACL" \
    --query 'NetworkAcls[0].Associations[0].SubnetId' \
    --output text)

if ! [ "$acl_association_check" == "$subnet_id" ]; then
    
    new_acl_association_id=$(aws ec2 replace-network-acl-association --association-id "$network_acl_association_id" \
        --network-acl-id "$acl_id" \
        --query 'NewAssociationId' \
        --output text)
    
    if [ "$new_acl_association_id" == "None" ] || [ "$new_acl_association_id" == "" ]; then
    
        echo "ERROR in ACL Association."
        exit 1
    
    fi

    echo "ACL is Associated Successfully to Subnet-id: $subnet_id."

else

    echo "ACL is Already Associated to Subnet-id: $subnet_id."

fi    