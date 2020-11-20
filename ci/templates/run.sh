#!/bin/bash
# Run script for packer AMI builds

set -e
cd templates
echo "========== CPU-amd64 Build =========="
/root/packer build -var type=cpu -machine-readable template.json | tee cpu_amd64_build.log
echo "========== GPU-amd64 Build =========="
/root/packer build -var type=gpu -machine-readable template.json | tee gpu_amd64_build.log
echo "========== CPU-aarch64 Build =========="
/root/packer build -var type=cpu -var arch=aarch64 -var instance=t4g.medium -machine-readable template.json | tee cpu_aarch64_build.log
echo "========== Artifacts =========="
cpu_amd64_id=`cat cpu_amd64_build.log | grep "artifact" | grep ",id," | cut -d "," -f 6 | cut -d ":" -f 2`
gpu_amd64_id=`cat gpu_amd64_build.log | grep "artifact" | grep ",id," | cut -d "," -f 6 | cut -d ":" -f 2`
cpu_aarch64_id=`cat cpu_aarch64_build.log | grep "artifact" | grep ",id," | cut -d "," -f 6 | cut -d ":" -f 2`
echo "CPU-amd64 AMI: ${cpu_amd64_id}"
echo "GPU-amd64 AMI: ${gpu_amd64_id}"
echo "CPU-aarch64 AMI: ${cpu_aarch64_id}"
