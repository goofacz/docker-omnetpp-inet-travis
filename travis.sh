#!/bin/bash

set -e

function build_stage {
    if [ -z "$SMILE_FRAMEWORK" ]
    then
        echo "********************************************************************************"
        echo " Clone SMILe"
        echo "********************************************************************************"
        git -c http.sslVerify=false clone https://github.com/goofacz/smile.git /root/smile
    fi

    echo "********************************************************************************"
    echo " Build SMILe"
    echo "********************************************************************************"
    cd /root/smile
    make makefiles
    make -j $(nproc) MODE=release V=1
    
    echo "*** Install Python dependencies with pip"
    pip3 install -r requirements.txt
    
    echo "*** Set PYTHONPATH environment variable"
    export PYTHONPATH=/root/smile/python

    if [ -z "$SMILE_FRAMEWORK" ]
    then
        echo "********************************************************************************"
        echo " Build $PROJECT_NAME"
        echo "********************************************************************************"
        cd /root/$PROJECT_NAME

        make makefiles
        make -j $(nproc) MODE=release V=1
    fi
} # function build_stage

function run_omnetpp_tests_stage {
    if [ ! -d "/root/$PROJECT_NAME/tests" ]
    then
        echo "*** Skipping OMNET++ tests, directory \"/root/$PROJECT_NAME/tests\" was not found"
        return
    fi

    echo "********************************************************************************"
    echo " Running OMNET++ tests"
    echo "********************************************************************************"

    cd /root/$PROJECT_NAME/tests
    ./runtest
    FAILURES_FOUND=`opp_test check -p smile * | grep "FAIL: 0" | wc -l`
    if [ "$FAILURES_FOUND" -eq "0" ]
    then
        exit 1
    fi
} # run_omnetpp_tests_stage

function run_python_tests_stage {
    if [ ! -d "/root/$PROJECT_NAME/python/tests" ]
    then
        echo "*** Skipping Python tests, directory \"/root/$PROJECT_NAME/python/tests\" was not found"
        return
    fi

    echo "********************************************************************************"
    echo " Running Python tests"
    echo "********************************************************************************"

    cd /root/$PROJECT_NAME/python
    python3 -m unittest tests/*
} # run_python_tests_stage

echo "********************************************************************************"
if [ -z "$SMILE_FRAMEWORK" ]
then
    echo " Building & testing component based on SMILe framework"
else
    echo " Building & testing SMILe framework"
fi
echo "********************************************************************************"

if [ -z "$PROJECT_NAME" ]
then
    echo "PROJECT_NAME environment variable is unset"
    exit 1
fi

build_stage
run_omnetpp_tests_stage
run_python_tests_stage

exit 0
