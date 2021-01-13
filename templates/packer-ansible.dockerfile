FROM rdouglass/packer-ansible:latest

RUN apt-get install -y python3-distutils python3-apt && \
    wget https://bootstrap.pypa.io/get-pip.py -O get-pip.py && \
    python3 get-pip.py && \
    pip install requests