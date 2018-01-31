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


function run_omnetpp_tests_stage {
    if [ ! -d "/root/smile/tests" ]
    then
        echo "*** Skipping OMNET++ tests, directory \"/root/smile/tests\" was not found"
        return
    fi

    echo "*** Running OMNET++ tests"

    cd /root/smile/tests
    ./runtest
    FAILURES_FOUND=`opp_test check -p smile * | grep "FAIL: 0" | wc -l`
    if [ "$FAILURES_FOUND" -eq "0" ]
    then
        exit 1
    fi
} # run_omnetpp_tests_stage

if [ -z "$SMILE_FRAMEWORK" ]
then
    echo "*** Building & testing component based on SMILe framework"
else
    echo "*** Building & testing SMILe framework"
fi

build_stage
run_omnetpp_tests_stage

exit 0
