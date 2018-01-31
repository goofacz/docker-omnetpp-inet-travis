#!/bin/bash

set -e

function build_stage {
    echo "*** Build SMILe"
    
    if [ "$SMILE_CI_MODE" == "FRAMEWORK" ]
    then
        git -c http.sslVerify=false clone https://github.com/goofacz/smile.git /root/smile
    fi
    
    cd /root/smile
    make makefiles
    make -j $(nproc) MODE=release V=1
    
    echo "*** Install Python dependencies"
    pip3 install -r requirements.txt
    
    echo "*** Set environment variables"
    export PYTHONPATH=/root/smile/python 
} # function build_stage


if [ -z "$SMILE_CI_MODE" ]
then
    echo "Unknown or unset SMILE_CI_MODE environment variable"
    exit -1
fi

build_stage

exit 0
