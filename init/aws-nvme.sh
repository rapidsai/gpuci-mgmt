#!/bin/bash
#
# Copyright (c) 2019, NVIDIA CORPORATION.
#
# AWS init script for gpuCI nodes with nvme drives on nodes
#

SCRIPT_NAME="$0"
function logger {
  TS=`date +%F_%H-%M-%S`
  echo "[$SCRIPT_NAME $TS] $@"
}

function apt-butler {
  logger "apt-butler tasked to run 'sudo apt-get ${@}'"
  i=0
  tput sc
  while fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1 ; do
      case $(($i % 4)) in
          0 ) j="-" ;;
          1 ) j="\\" ;;
          2 ) j="|" ;;
          3 ) j="/" ;;
      esac
      tput rc
      echo -en "\r[$j] Waiting for other software managers to finish..." 
      sleep 1
      ((i=i+1))
  done
  sudo apt-get ${@}
}

logger "Add delay for cron apt-get update/upgrade job"
sudo sed -i '2s/.*/sleep 900/' /etc/cron.daily/apt-compat
sudo service cron restart

logger "Wait for system apt-get update/upgrade to finish"
i=0
tput sc
while fuser /var/lib/dpkg/lock >/dev/null 2>&1 ; do
    case $(($i % 4)) in
        0 ) j="-" ;;
        1 ) j="\\" ;;
        2 ) j="|" ;;
        3 ) j="/" ;;
    esac
    tput rc
    echo -en "\r[$j] Waiting for other software managers to finish..." 
    sleep 1
    ((i=i+1))
done

logger "Update/upgrade image first; before unattended-upgrades runs"
apt-butler update
apt-butler upgrade -y

set -e

logger "Check if nvme is already mounted; if not format and mount"
# Need this pkg for selecting correct nvme
apt-butler install -y nvme-cli
INSTANCE_NVME=`sudo nvme list | grep "Amazon EC2 NVMe Instance Storage" | awk '{ print $1 }'`
logger "Instance NVMe found - $INSTANCE_NVME"
if ! grep -qa "$INSTANCE_NVME /jenkins " /proc/mounts; then
  logger "$INSTANCE_NVME not mounted, mounting and formatting"
  sudo mkfs -t ext4 $INSTANCE_NVME && sudo mkdir -p /jenkins && sudo mount $INSTANCE_NVME /jenkins
else
  logger "$INSTANCE_NVME already mounted"
fi

logger "Install awscli"
apt-butler install -y awscli

logger "Check mounts"
mount
df -h

logger "Ensure ubuntu user has full rights on directory for Jenkins work"
sudo chown -R ubuntu:ubuntu /jenkins

logger "Move /tmp to NVMe for faster perf"
sudo mv /tmp /jenkins
sudo ln -s /jenkins/tmp /tmp

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

logger "Ensure docker system is clean"
docker system prune -f

logger "Connect node to Jenkins"
wget https://gpuci.gpuopenanalytics.com/plugin/ec2/AMI-Scripts/ubuntu-ami-setup.sh
sudo sh ubuntu-ami-setup.sh gpuci.gpuopenanalytics.com
