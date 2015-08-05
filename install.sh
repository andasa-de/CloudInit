#!/bin/bash

META_URL=http://169.254.169.254/latest/meta-data/

if [ -z $INSTANCE_ID ]; then
  INSTANCE_ID=$(wget -qO- $META_URL/instance-id)
fi

if [ -z $INSTANCE_ID ]; then
  echo Unable to retrieve instance-id. Are you running this script on a AWS EC2 instance?
  exit 1
fi

if [ -z $AWS_REGION ]; then
  AWS_REGION=$(wget -qO- $META_URL/placement/availability-zone)
  AWS_REGION=${AWS_REGION:0:-1}
fi

if [ -z $TAG_KEY ]; then
  TAG_KEY=Components
fi

echo Initializing Instance $INSTANCE_ID in $AWS_REGION

aws ec2 describe-tags \
  --filter Name=resource-id,Values=$INSTANCE_ID Name=key,Values=$TAG_KEY \
  --region $AWS_REGION \
  --output text | grep -o '[[:alnum:]-]*' | tail -n+5
