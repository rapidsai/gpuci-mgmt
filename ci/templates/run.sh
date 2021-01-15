#!/bin/bash
# Run script for packer AMI builds

set -e
cd templates
echo "========== CPU-amd64 Build =========="
/root/packer build -var type=cpu -machine-readable template.json | tee cpu_amd64_build.log
echo "========== GPU-amd64 Build =========="
/root/packer build -var type=gpu -machine-readable template.json | tee gpu_amd64_build.log
echo "========== CPU-arm64 Build =========="
/root/packer build -var type=cpu -var arch=arm64 -var instance=a1.large -machine-readable template.json | tee cpu_arm64_build.log
echo "========== Artifacts =========="
export CPU_AMI_AMD64=`cat cpu_amd64_build.log | grep "artifact" | grep ",id," | cut -d "," -f 6 | cut -d ":" -f 2`
export GPU_AMI_AMD64=`cat gpu_amd64_build.log | grep "artifact" | grep ",id," | cut -d "," -f 6 | cut -d ":" -f 2`
export CPU_AMI_ARM64=`cat cpu_arm64_build.log | grep "artifact" | grep ",id," | cut -d "," -f 6 | cut -d ":" -f 2`
echo "CPU-amd64 AMI: ${CPU_AMI_AMD64}"
echo "GPU-amd64 AMI: ${GPU_AMI_AMD64}"
echo "CPU-arm64 AMI: ${CPU_AMI_ARM64}"
