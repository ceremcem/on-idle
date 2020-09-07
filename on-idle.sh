#!/bin/bash
set -eu -o pipefail
safe_source () { [[ ! -z ${1:-} ]] && source $1; _dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; _sdir=$(dirname "$(readlink -f "$0")"); }; safe_source

# Example usage:
# Run `command` after 10 seconds of idle:
# $0 10 command

DEBUG=

idle=false
idleAfter=$1
idleAfterMs=$(($idleAfter * 1000))
shift

log(){
    echo "`date +"%d.%m.%Y %H:%M:%S"`  : $@"
}

function format_seconds() {
  (($1 >= 86400)) && printf '%d days and ' $(($1 / 86400)) # days
  (($1 >= 3600)) && printf '%02d:' $(($1 / 3600 % 24))     # hours
  (($1 >= 60)) && printf '%02d:' $(($1 / 60 % 60))         # minutes
  printf '%02d%s\n' $(($1 % 60)) "$( (($1 < 60 )) && echo ' s.' || echo '')"
}

exe_pid=
cleanup(){
    log "Cleaning up"
    [[ -n $exe_pid ]] && kill $exe_pid 2> /dev/null
}

trap cleanup EXIT

IDLE_EXE=$_sdir/getIdle
# copy to RAM if possible
if cp $IDLE_EXE /dev/shm; then
    IDLE_EXE=/dev/shm/getIdle
else
    log "IDLE_EXE can not be copied to RAM (/dev/shm)"
fi

while :; do
    $IDLE_EXE > /dev/null \
        && break \
        || { \
            log "Waiting for 'getIdle' to become ready..."; \
            sleep 5; \
           }
done
pollInterval=0.2
idleBase=0 # milliseconds, the offset
idleTimeMsNew=
log "Started idle watchdog. Timeout is: $(format_seconds $idleAfter)"
while true; do
  _idleTimeMsNew=$idleTimeMsNew
  idleTimeMsNew=$($IDLE_EXE)
  if [[ -n ${idleTimeMs:-} ]]; then 
    if [[ $idle = false && $idleTimeMsNew -lt $idleTimeMs ]]; then
      testDuration="0.2"; testDurationMs="200";
      sleep $testDuration
      testIdleMs=$($IDLE_EXE)
      testDiff=$(($testIdleMs - $testDurationMs - $idleTimeMsNew))
      if [[ $testDiff -gt 0 ]]; then 
        idleBase=$(($idleBase + $idleTimeMs))
        [[ -n $DEBUG ]] && log "DEBUG: adding offset by ${idleTimeMs}ms, total: $(($idleBase / 1000))s (testDiff: $testDiff)"
      else
        [[ -n $DEBUG ]] && log "DEBUG: resetting idleBase counter (testDiff: $testDiff)"
        idleBase=0
      fi
    fi 
  fi 
  idleTimeMs=$idleTimeMsNew
  #echo $idleTimeMillis  # just for debug purposes.
  if [[ $idle = false && $(($idleTimeMs + $idleBase)) -gt $idleAfterMs ]] ; then
    log "Computer is now idle. (after $(format_seconds $idleAfter))"   # or whatever command(s) you want to run...
    "$@" & exe_pid=$!
    idle=true
  fi

  if [[ $idle = true && $(($idleTimeMs + $idleBase)) -lt $idleAfterMs ]] ; then
    log "end idle"     # same here.
    kill $exe_pid 2> /dev/null
    exe_pid=
    idle=false
    idleBase=0
  fi
  sleep $pollInterval
done
