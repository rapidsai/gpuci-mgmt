FROM ubuntu:18.04

ENV PATH=/root:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

RUN apt-get update && \
    apt-get install -y software-properties-common && \
    apt-add-repository --yes --update ppa:ansible/ansible && \
    apt-get update && \
    apt-get install -y ansible unzip wget python3-distutils python3-apt

RUN wget 'https://releases.hashicorp.com/packer/1.5.6/packer_1.5.6_linux_amd64.zip' &&  \
    unzip 'packer_1.5.6_linux_amd64.zip'

RUN wget https://bootstrap.pypa.io/get-pip.py && \
    python3 get-pip.py && \
    pip install requests
