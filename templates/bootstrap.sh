#!/bin/bash
set -ex
df -h
lsblk
apt-get update
apt-get -y upgrade
apt-get install -y python3-dev python3-pip