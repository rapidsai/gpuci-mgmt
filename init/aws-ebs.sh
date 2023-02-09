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

logger "Override docker setup"
sudo service docker stop
if [ -f /etc/docker/daemon.json ]; then
  sudo cat /etc/docker/daemon.json
fi
cat <<EOL > /tmp/daemon.json
{
    "experimental": true
}
EOL
sudo mv /tmp/daemon.json /etc/docker/daemon.json
sudo cat /etc/docker/daemon.json
sudo service docker start

logger "Ensure docker system is clean"
set +e
docker system prune -f

# Setup hourly cron to prune images
sudo cat > /etc/docker/image-prune.sh <<EOF
#!/bin/bash

df -h -t ext4
docker images
docker image prune -a -f --filter "until=12h"
docker images
docker volume ls
docker volume prune -f
docker volume ls
docker container ls
docker container prune -f
docker container ls
df -h -t ext4
EOF
sudo chmod +x /etc/docker/image-prune.sh
sudo crontab -l > /tmp/existing-crons | true
sudo echo "0 */3 * * * /etc/docker/image-prune.sh" >> /tmp/existing-crons
sudo crontab /tmp/existing-crons

logger "Connect node to Jenkins"
wget https://gpuci.gpuopenanalytics.com/plugin/ec2/AMI-Scripts/ubuntu-ami-setup.sh
sudo sh ubuntu-ami-setup.sh gpuci.gpuopenanalytics.com

