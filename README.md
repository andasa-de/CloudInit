# CloudInit

This project runs docker containers via docker-compose on EC2 instances. To initialize an instance set the user-data to a cloud-init script similar to this:

```
#!/bin/bash

apt-get update
apt-get -qqy dist-upgrade
apt-get -qqy install libffi-dev libssl-dev python-pip
pip install -q awscli pyopenssl ndg-httpsclient pyasn1 requests Jinja2

wget -qO- https://get.docker.com/ | sh
curl -L https://github.com/docker/compose/releases/download/1.3.3/docker-compose-`uname -s`-`uname -m` > /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
sudo usermod -aG docker ubuntu

export AWS_S3_PREFIX=s3://my-deployment-bucket
wget -qO- https://raw.githubusercontent.com/andasa-de/CloudInit/master/install.sh | bash
```

Additionally set the following metadata tags on the instance
```
Environment=ABC
Components=comp1, comp2, comp3
```

The script will configure the instance to run all docker-compose configurations located at `s3://my-deployment-bucket/{{ Environment }}/compN.yml`
