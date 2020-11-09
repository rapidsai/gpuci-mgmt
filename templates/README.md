# gpuCI AMI Templates

This directory contains a [packer](https://www.packer.io/) template for building gpuCI AMIs.

## Building the images

1. [Setup AWS credentials](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-configure.html)
2. [Ensure the security group](https://docs.aws.amazon.com/vpc/latest/userguide/VPC_SecurityGroups.html#SecurityGroupRules) in the template allows your IP to SSH
3. Install packer (perhaps via `brew install packer`)
4. `packer build -var type=cpu template.json` or `packer build -var type=gpu template.json`

## Components

### Packer templates

#### EC2 builds

The main template is `template.json`, with the following variables:

**NOTE:** `aarch64` only works for `cpu` type builds currently; `amd64` works for both `cpu` and `gpu` types

Variable | Values | Default | Purpose
--- | --- | --- | ---
`type` | `cpu` OR `gpu` | `cpu` | Type of image to build
`arch` | `amd64` OR `aarch64` | `amd64` | Architecture of the build
`instance` | `t2.medium` for `amd64` OR<br> `t4g.medium` for `aarch64` | `t2.medium` | Instance to use for build

Define these with `-var <variable>=<value>` when issuing the `packer build` command

#### Local docker builds

`docker.json` is a template which builds a docker image with the same scripts. This is useful for quick tests without having to wait for EC2 instances.

### Scripts

There are two scripts:
- `bootstrap.sh` - Bootstraps a python installation to allow Ansible to work
- `post_build.sh` - Outputs some debug information after the packer build completes

### Ansible

There is a single playbook (`playbook.yml`) which has two different groups to run different roles.

There are a few roles:
- `common` - Common packages/installs between CPU & GPU
- `cpu` - CPU specific installs
- `gpu` - GPU specific installs (NVIDIA drivers, CUDA, etc)
- `post_common` - Actions common to both CPU & GPU performed after type-specific role
