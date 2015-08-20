#!/bin/bash

COMP=$1
ENV=$2

if [[ -z $COMP || -z $ENV ]]; then
  echo "Usage: docker_compose_installer.sh {component} {environment}"
  exit 1
fi

if [ -z $AWS_S3_PREFIX ]; then
  echo "Please set AWS_S3_PREFIX before running this script"
  exit 1
fi

if [ -z $INSTALL_DIR ]; then
  INSTALL_DIR=/components
fi

if [[ -z $(pip list | grep Jinja2) ]]; then
  pip install Jinja2
fi

if [[ -z $(pip list | grep requests) ]]; then
  pip install requests
fi

mkdir -p $INSTALL_DIR

ENG=https://raw.githubusercontent.com/andasa-de/CloudInit/master/j2render.py
TMP=https://raw.githubusercontent.com/andasa-de/CloudInit/master/initd.j2
SRC=$AWS_S3_PREFIX/$ENV/$COMP.yml
DST=$INSTALL_DIR/$COMP.yml

wget -qO- $ENG | python $TMP --component=$COMP --components_path=$INSTALL_DIR --region=$AWS_REGION --yml_src=$SRC > /etc/init.d/$COMP
chmod +x /etc/init.d/$COMP
update-rc.d

/etc/init.d/$COMP update
/etc/init.d/$COMP start
