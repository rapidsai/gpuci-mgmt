#!/bin/bash
#
# Copyright (c) 2019, NVIDIA CORPORATION.
#
# AWS init script for gpuCI nodes with EBS only storage
#
set -e

SCRIPT_NAME="$0"
function logger {
  TS=`date +%F_%H-%M-%S`
  echo "[$SCRIPT_NAME $TS] $@"
}

logger "Check mounts"
mount
df -h

logger "Ensure ubuntu user has full rights on directory for Jenkins work"
sudo mkdir -p /jenkins
sudo chown -R ubuntu:ubuntu /jenkins

logger "Override docker setup and utilize internal docker registry mirror"
sudo service docker stop
sudo cat /etc/docker/daemon.json
cat <<EOL > /tmp/daemon.json
{
    "registry-mirrors": ["http://docker-mirror.rapids.ai:5000"],
    "experimental": true
}
EOL
sudo mv /tmp/daemon.json /etc/docker/daemon.json
sudo cat /etc/docker/daemon.json
sudo service docker start

logger "Turn on unattended-upgrades"
sudo apt-get update && sudo apt-get install -y unattended-upgrades

logger "Ensure docker system is clean"
set +e
docker system prune -f

logger "Connect node to Jenkins"
wget https://gpuci.gpuopenanalytics.com/plugin/ec2/AMI-Scripts/ubuntu-ami-setup.sh
sudo sh ubuntu-ami-setup.sh gpuci.gpuopenanalytics.com
