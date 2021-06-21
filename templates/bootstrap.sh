#!/bin/bash
set -ex
if [[ "$PACKER_BUILDER_TYPE" != "docker" ]]; then
    sleep 30
fi
df -h
lsblk
apt-get update
apt-get -y upgrade
apt-get install -y python3-dev python3-pip