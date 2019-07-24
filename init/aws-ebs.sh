#!/bin/bash
#
# Copyright (c) 2019, NVIDIA CORPORATION.
#
# AWS init script for gpuCI nodes with EBS only storage
#


# Update/upgrade image first; before unattended-upgrades runs
sudo apt-get update && sudo apt-get upgrade -y && sudo apt-get clean

# Check mounts
mount
df -h

# Ensure ubuntu user has full rights on directory for Jenkins work
sudo mkdir -p /jenkins
sudo chown -R ubuntu:ubuntu /jenkins

# Override docker setup and utilize internal docker registry mirror
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

# Ensure docker system is clean
docker system prune -f

# Connect node to Jenkins
wget https://gpuci.gpuopenanalytics.com/plugin/ec2/AMI-Scripts/ubuntu-ami-setup.sh
sudo sh ubuntu-ami-setup.sh gpuci.gpuopenanalytics.com
