#!/bin/bash

META_URL=http://169.254.169.254/latest/meta-data/

if [ -z $INSTANCE_ID ]; then
  INSTANCE_ID=$(wget -qO- $META_URL/instance-id)
fi

if [ -z $INSTANCE_ID ]; then
  logger -s Unable to retrieve instance-id. Are you running this script on a AWS EC2 instance?
  exit 1
fi

if [ -z $AWS_REGION ]; then
  AWS_REGION=$(wget -qO- $META_URL/placement/availability-zone)
  AWS_REGION=${AWS_REGION:0:-1}
fi

if [ -z $COMP_TAG_KEY ]; then
  COMP_TAG_KEY=Components
fi

if [ -z $ENV_TAG_KEY ]; then
  ENV_TAG_KEY=Environment
fi

if [ -z $ENV ]; then
  ENV=$(aws ec2 describe-tags \
    --filter Name=resource-id,Values=$INSTANCE_ID Name=key,Values=$ENV_TAG_KEY \
    --region $AWS_REGION \
    --output text | grep -o '[[:alnum:]-]*' | tail -n+5)
fi

if [ -z $ENV ]; then
  logger -s Missing Tag $ENV_TAG_KEY
  exit 1
fi

if [ -z $COMP_INSTALLER_URL ]; then
  COMP_INSTALLER_URL=https://raw.githubusercontent.com/andasa-de/CloudInit/master/docker_compose_installer.sh
fi

logger -s Initializing Instance $INSTANCE_ID in $AWS_REGION

export AWS_REGION
aws ec2 describe-tags \
  --filter Name=resource-id,Values=$INSTANCE_ID Name=key,Values=$COMP_TAG_KEY \
  --region $AWS_REGION \
  --output text | grep -o '[[:alnum:]-]*' | tail -n+5 | while read -r COMP;
do
  logger -s Installing $COMP...
  wget -qO- $COMP_INSTALLER_URL | bash -s $COMP $ENV
  if [ $? != 0 ]; then
    logger -s Error while installing $COMP
    exit $?
  fi
done
