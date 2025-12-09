#!/bin/bash

set -e

VOLUME_TYPE="io2"
SIZE=12
IOPS=8000
AZ="us-east-1c"
INSTANCE_ID="i-0faf76fee3369542d"

VOLUME_ID=$(aws ec2 create-volume \
    --volume-type "$VOLUME_TYPE" \
    --size "$SIZE" \
    --availability-zone "$AZ" \
    --iops "$IOPS" \
    --query 'VolumeId' \
    --output text)

echo "New Volume Was Created Successfully With ID -> \"$VOLUME_ID\" ✅"

aws ec2 wait volume-available --volume-ids "$VOLUME_ID"

aws ec2 attach-volume \
    --volume-id "$VOLUME_ID" \
    --instance-id "$INSTANCE_ID" \
    --device /dev/sdf \
    > /dev/null

echo "New Volume With ID -> \"$VOLUME_ID\" Was Attached To The Machine With ID -> \"$INSTANCE_ID\" Successfully ✅"

aws ec2 delete-volume \
    --volume-id "$VOLUME_ID" \
    > /dev/null