#!/bin/bash
set -ex
#sleep 30
df -h
lsblk
apt-get update
apt-get -y upgrade
apt-get install -y python-dev python-pip