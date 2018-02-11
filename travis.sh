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
    echo "********************************************************************************"
    echo " Running OMNET++ tests"
    echo "********************************************************************************"

    if [ ! -d "/root/$PROJECT_NAME/tests" ]
    then
        echo "*** Skipping OMNET++ tests, directory \"/root/$PROJECT_NAME/tests\" was not found"
        return
    fi

    cd /root/$PROJECT_NAME/tests
    ./runtest
    FAILURES_FOUND=`opp_test check -p smile * | grep "FAIL: 0" | wc -l`
    if [ "$FAILURES_FOUND" -eq "0" ]
    then
        exit 1
    fi
} # run_omnetpp_tests_stage

function run_python_tests_stage {
    echo "********************************************************************************"
    echo " Running simple stationary simulation"
    echo "********************************************************************************"

    if [ ! -f "/root/$PROJECT_NAME/simulations/omnetpp.ini" ]
    then
        echo "*** Skipping simulation, \"/root/$PROJECT_NAME/simulations/omnetpp.ini\" was not found"
        return
    fi

    CONFIG_DEFINED=`grep travis_simple_stationary_simulation /root/$PROJECT_NAME/simulations/omnetpp.ini | wc -l`
    if [ "$CONFIG_DEFINED" -eq "0" ]
    then
        echo "*** Skipping simulation, configuration \"travis_simple_stationary_simulation\" was not found"
        return
    fi

    cd /root/$PROJECT_NAME
    opp_run -u Cmdenv -n ../inet/src/:../smile/src/:../smile/simulations/:./src/:./simulations/ ./simulations/omnetpp.ini -l ../inet/src/INET -l ../smile/src/smile -l ./src/$PROJECT_NAME -c travis_simple_stationary_simulation
} # run_python_tests_stage

function run_simple_stationary_simulation {

} # run_simple_stationary_simulation

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
