#!/bin/bash
# Tools for gpuCI scripts

URL="https://github.com/rapidsai/gpuci-mgmt"

function logger {
  TS=`date`
  echo "[$TS] $@"
}

logger "Installing utils script..."
source /dev/stdin <<< "$(curl --insecure $URL/tools/utils.sh)"

logger "Tools installed..."
