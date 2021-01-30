#!/bin/bash

on_kill(){
    echo "kill signal is ignored."
}
trap -- on_kill SIGTERM SIGHUP SIGINT
echo "$(basename $0) will exit in 10 seconds."
sleep 2
echo "TESTER: NOW DISTURB for 2 seconds."
sleep 10
echo "$(basename $0) is ended."
exit 0
