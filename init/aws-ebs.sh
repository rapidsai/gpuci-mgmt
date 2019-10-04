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

function apt-butler {
  logger "apt-butler tasked to run 'sudo apt-get ${@}'"
  i=0
  while sudo lsof /var/lib/dpkg/lock /var/lib/dpkg/lock-frontend 2>&1 > /dev/null ; do
      logger "apt-butler ... waiting for apt instances to finish ..."
      sleep 5
      ((i=i+1))
  done
  sleep 5
  while sudo lsof /var/lib/dpkg/lock /var/lib/dpkg/lock-frontend 2>&1 > /dev/null ; do
      logger "apt-butler ... waiting for apt instances to finish ..."
      sleep 5
      ((i=i+1))
  done
  logger "apt-butler running 'sudo apt-get ${@}'"
  DEBIAN_FRONTEND=noninteractive sudo apt-get ${@}
  logger "apt-butler finished 'sudo apt-get ${@}'"
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
apt-butler install -y unattended-upgrades

logger "Ensure docker system is clean"
set +e
docker system prune -f

logger "Connect node to Jenkins"
wget https://gpuci.gpuopenanalytics.com/plugin/ec2/AMI-Scripts/ubuntu-ami-setup.sh
sudo sh ubuntu-ami-setup.sh gpuci.gpuopenanalytics.com
