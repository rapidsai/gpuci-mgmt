# gpuCI AMI Templates

This directory contains [packer](https://www.packer.io/) templates for building gpuCI AMIs.

## Building the images

1. Setup AWS keys
2. Ensure the security group allows your IP to SSH
3. Install packer (perhaps via `brew install packer`)
4. `packer build -var type=cpu template.json` or `packer build -var type=gpu template.json`

## Components

### Packer templates

There is a single template `template.json` which builds either CPU or GPU with a user variable called `type`.

### Scripts

There are two scripts:
- `bootstrap.sh` - Bootstraps a python installation to allow Ansible to work
- `post_build.sh` - Outputs some debug information after the packer build completes

### Ansible

There are two playbooks:
- `playbook_cpu.yml` - For the CPU type
- `playbook_gpu.yml` - For the GPU type

Each playbook has a few roles:
- `common` - Common packages/installs between CPU & GPU
- `cpu` - CPU specific installs
- `gpu` - GPU specific installs (NVIDIA drivers, CUDA, etc)
- `post_common` - Actions common to both CPU & GPU performed after type-specific role