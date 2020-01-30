#!/bin/bash
# Tools for gpuCI scripts

URL="https://raw.githubusercontent.com/rapidsai/gpuci-mgmt/master/tools"

function logging {
  TS=`date`
  echo "[$TS] $@"
}

function install_tool {
  logging "Installing $1 script..."
  SAVE_LOC="$HOME/bin/${1}"
  curl --insecure -q "${URL}/${1}" > $SAVE_LOC
  logging "Installed $1 script..."
}

logging "Creating ~/bin dir..."
mkdir -p $HOME/bin

install_tool retry
install_tool logger

logging "Adding ~/bin to PATH..."
export PATH="$HOME/bin:$PATH"

logging "Tools installed..."
