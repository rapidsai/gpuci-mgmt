#!/bin/bash
# Tools for gpuCI scripts

URL="https://raw.githubusercontent.com/rapidsai/gpuci-mgmt/master/tools"

function logger {
  TS=`date`
  echo "[$TS] $@"
}

logger "Installing utils script..."
source /dev/stdin <<< "$(curl --insecure $URL/utils.sh)"

logger "Tools installed..."
