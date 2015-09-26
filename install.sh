#!/bin/bash

META_URL=http://169.254.169.254/latest/meta-data/

if [ -z $INSTANCE_ID ]; then
  INSTANCE_ID=$(wget -qO- $META_URL/instance-id)
fi

if [ -z $INSTANCE_ID ]; then
  logger -s Unable to retrieve instance-id. Are you running this script on a AWS EC2 instance?
  exit 1
fi

if [ -z $AWS_S3_PREFIX ]; then
  echo "Please set AWS_S3_PREFIX before running this script"
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

if [ -z $INSTALL_DIR ]; then
  INSTALL_DIR=/components
fi

mkdir -p $INSTALL_DIR

logger -s Initializing Instance $INSTANCE_ID in $AWS_REGION

function docker-compose-install {
  COMP=$1
  ENG=https://raw.githubusercontent.com/andasa-de/CloudInit/master/j2render.py
  TMP=https://raw.githubusercontent.com/andasa-de/CloudInit/master/initd.j2
  SRC=$AWS_S3_PREFIX/$ENV/$COMP.yml
  DST=$INSTALL_DIR/$COMP.yml

  wget -qO- $ENG > j2render.py
  python j2render.py $TMP --component=$COMP --components_path=$INSTALL_DIR --region=$AWS_REGION --yml_src=$SRC > /etc/init.d/$COMP
  chmod +x /etc/init.d/$COMP
  update-rc.d $COMP defaults

  /etc/init.d/$COMP update
  /etc/init.d/$COMP start
}

aws ec2 describe-tags \
  --filter Name=resource-id,Values=$INSTANCE_ID Name=key,Values=$COMP_TAG_KEY \
  --region $AWS_REGION \
  --output text | grep -o '[[:alnum:]-]*' | tail -n+5 | while read -r COMP;
do
  logger -s Installing $COMP...
  docker-compose-install $COMP
  if [ $? != 0 ]; then
    logger -s Error while installing $COMP
    exit $?
  fi
done
