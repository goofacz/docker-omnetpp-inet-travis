#!/bin/bash

set -e

function build_stage {
    if [ -z "$SMILE_FRAMEWORK" ]
    then
        echo "*** Clone SMILe"
        git -c http.sslVerify=false clone https://github.com/goofacz/smile.git /root/smile
    fi

    echo "*** Build SMILe"
    cd /root/smile
    make makefiles
    make -j $(nproc) MODE=release V=1
    
    echo "*** Install Python dependencies with pip"
    pip3 install -r requirements.txt
    
    echo "*** Set PYTHONPATH environment variable"
    export PYTHONPATH=/root/smile/python

    if [ -z "$SMILE_FRAMEWORK" ]
    then
        echo "*** Build repository under test"
        cd /root/repository
    fi
} # function build_stage


if [ -z "$SMILE_FRAMEWORK" ]
then
    echo "Building & testing SMILe framework"
else
    echo "Building & testing component based on SMILe framework"
fi

build_stage

exit 0
