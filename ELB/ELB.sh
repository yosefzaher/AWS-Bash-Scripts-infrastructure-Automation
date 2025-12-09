#!/bin/bash

ALB_ARN=$(aws elbv2 create-load-balancer --name test-elb \
    --type application \
    --subnets subnet-0b53d6d2866d089fa subnet-0eb7b7336ad2c5c21 \
    --region us-east-1 \
    --security-groups sg-0b14743f05176dff6 \
    --query 'LoadBalancers[0].LoadBalancerArn' \
    --output text)

echo "ALB_ARN = $ALB_ARN"

TG_ARN=$(aws elbv2 create-target-group --name test-tg-elb \
    --protocol HTTP \
    --port 8002 \
    --vpc-id vpc-063065df4192af86a \
    --health-check-protocol HTTP \
    --health-check-port 8002 \
    --target-type instance \
    --region us-east-1 \
    --query 'TargetGroups[0].TargetGroupArn' \
    --output text)

echo "TG_ARN = $TG_ARN"

aws elbv2 register-targets --target-group-arn "$TG_ARN" \
    --targets Id=i-047aee16a6dd6f4c8 Id=i-06a45cac07413108b \
    --region us-east-1 

LISTENER_ARN=$(aws elbv2 create-listener --load-balancer-arn "$ALB_ARN" \
    --protocol HTTP \
    --port 80 \
    --region us-east-1 \
    --default-actions Type=forward,TargetGroupArn="$TG_ARN" \
    --query 'Listeners[0].ListenerArn' \
    --output text)

echo "LISTENER_ARN = $LISTENER_ARN"