#!/bin/bash
#
# Copyright (c) 2019, NVIDIA CORPORATION.
#
# AWS init script for gpuCI nodes with nvme drives on nodes
#
set -e

SCRIPT_NAME="$0"
function logger {
  TS=`date +%F_%H-%M-%S`
  echo "[$SCRIPT_NAME $TS] $@"
}

logger "Override docker setup and utilize internal docker registry mirror"
sudo service docker stop
if [ -f /etc/docker/daemon.json ]; then
  sudo cat /etc/docker/daemon.json
fi
cat <<EOL > /tmp/daemon.json
{
    "registry-mirrors": ["http://docker-mirror.rapids.ai:5000"],
    "experimental": true
}
EOL
sudo mv /tmp/daemon.json /etc/docker/daemon.json
sudo cat /etc/docker/daemon.json

logger "Add jenkins user to docker group"
sudo usermod -a -G docker jenkins
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

