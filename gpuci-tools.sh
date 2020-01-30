#!/bin/bash
# Tools for gpuCI scripts

URL="https://raw.githubusercontent.com/rapidsai/gpuci-mgmt/master/tools"

function logging {
  TS=`date`
  echo "[$TS] $@"
}

function install_tool {
  logging "Installing $1 script..."
  SAVE_LOC=/tmp/${1}
  curl --insecure "${URL}/${1}" > $SAVE_LOC
  source $SAVE_LOC
  rm -f $SAVE_LOC
  logging "Installed $1 script..."
}

install_tool utils.sh

logging "Tools installed..."
