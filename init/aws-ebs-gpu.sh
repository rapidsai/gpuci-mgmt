#!/bin/bash
#
# Copyright (c) 2019, NVIDIA CORPORATION.
#
# AWS init script for gpuCI nodes with EBS only storage, nv-docker, and jenkins user (1001/1001)
#

SCRIPT_NAME="$0"
function logger {
  TS=`date +%F_%H-%M-%S`
  echo "[$SCRIPT_NAME $TS] $@"
}

logger "Update/upgrade image first; before unattended-upgrades runs"
sudo apt-get update && sudo apt-get upgrade -y && sudo apt-get clean

logger "Check mounts"
mount
df -h

logger "Create jenkins user"
sudo useradd -u 1001 jenkins
sudo usermod -aG adm,sudo,docker jenkins

logger "Ensure jenkins user has full rights on directory for Jenkins work"
sudo mkdir -p /jenkins
sudo chown -R jenkins:jenkins /jenkins

logger "Override docker setup and utilize internal docker registry mirror"
sudo service docker stop
sudo cat /etc/docker/daemon.json
cat <<EOL > /tmp/daemon.json
{
    "runtimes": {
        "nvidia": {
            "path": "nvidia-container-runtime",
            "runtimeArgs": []
        }
    },
    "registry-mirrors": ["http://docker-mirror.rapids.ai:5000"],
    "experimental": true
}
EOL
sudo mv /tmp/daemon.json /etc/docker/daemon.json
sudo cat /etc/docker/daemon.json
sudo service docker start

logger "Ensure docker system is clean"
docker system prune -f

logger "Connect node to Jenkins"
wget https://gpuci.gpuopenanalytics.com/plugin/ec2/AMI-Scripts/ubuntu-ami-setup.sh
sudo sh ubuntu-ami-setup.sh gpuci.gpuopenanalytics.com
