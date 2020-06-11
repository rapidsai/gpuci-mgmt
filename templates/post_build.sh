#!/bin/bash
set -ex
echo "========== Disk info =========="
df -h
lsblk
echo
echo "========== Python version =========="
python -V
echo
echo "========== Python3 version =========="
python3 -V
echo
echo "========== Pip list =========="
pip -V
pip list
echo
echo "========== Pip3 list =========="
pip3 -V
pip3 list
echo
echo "========== Apt list =========="
apt list --installed
echo