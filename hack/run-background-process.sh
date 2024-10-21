#!/bin/bash

BINARY=$1
PID_FILE=$2
LOG_FILE=$3

set -e

if [[ -f ${PID_FILE} ]]; then
    PID=$(cat ${PID_FILE})
    if [[ $(ps -p ${PID} -o command --no-headers) != "" ]]; then
        echo "${BINARY} already running"
        exit 0
    fi
fi

# start the process
nohup ${BINARY} > ${LOG_FILE} 2>&1 &
echo $! > ${PID_FILE}