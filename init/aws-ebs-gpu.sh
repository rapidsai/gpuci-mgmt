#!/bin/bash
#
# Copyright (c) 2019, NVIDIA CORPORATION.
#
# AWS init script for gpuCI nodes with EBS only storage, nv-docker
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
  while sudo lsof /var/lib/dpkg/lock* 2>&1 > /dev/null ; do
      logger "apt-butler ... waiting apt instances to finish ..."
      sleep 5
      ((i=i+1))
  done
  logger "apt-butler running 'sudo apt-get ${@}'"
  sudo apt-get ${@}
  logger "apt-butler finished 'sudo apt-get ${@}'"
}

logger "Add delay for cron apt-get update/upgrade job"
sudo sed -i '2s/.*/sleep 900/' /etc/cron.daily/apt-compat
sudo service cron restart

logger "Update/upgrade image first; before unattended-upgrades runs"
apt-butler update
apt-butler upgrade -y

logger "Install git-lfs and awscli"
curl -s https://packagecloud.io/install/repositories/github/git-lfs/script.deb.sh | sudo bash
apt-butler update
apt-butler install git-lfs awscli -y
git lfs install

logger "Check mounts"
mount
df -h

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
