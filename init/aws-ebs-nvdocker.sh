#!/bin/bash
#
# Copyright (c) 2019, NVIDIA CORPORATION.
#
# AWS init script for gpuCI nodes with EBS only storage and nv-docker
#


# Update/upgrade image first; before unattended-upgrades runs
sudo apt-get update && sudo apt-get upgrade -y && sudo apt-get clean

# Check mounts
mount
df -h

# Ensure ubuntu user has full rights on directory for Jenkins work
sudo mkdir -p /jenkins
sudo chown -R ubuntu:ubuntu /jenkins

# Override docker setup
sudo service docker stop
if [ -f /etc/docker/daemon.json ]; then
  sudo cat /etc/docker/daemon.json
fi
cat <<EOL > /tmp/daemon.json
{
    "runtimes": {
        "nvidia": {
            "path": "nvidia-container-runtime",
            "runtimeArgs": []
        }
    },
    "experimental": true
}
EOL
sudo mv /tmp/daemon.json /etc/docker/daemon.json
sudo cat /etc/docker/daemon.json
sudo service docker start

# Ensure docker system is clean
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

# Connect node to Jenkins
wget https://gpuci.gpuopenanalytics.com/plugin/ec2/AMI-Scripts/ubuntu-ami-setup.sh
sudo sh ubuntu-ami-setup.sh gpuci.gpuopenanalytics.com
