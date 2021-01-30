#!/bin/bash

cat << EOL
Instructions:

Disturb the system when yo see "DISTURB" directive.

Expect: on-idle.sh should't exit in any case.

EOL

../on-idle.sh 0:0:2 ./refuse-to-stop.sh
