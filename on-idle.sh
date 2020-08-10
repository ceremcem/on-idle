#!/bin/bash
set -eu -o pipefail
safe_source () { [[ ! -z ${1:-} ]] && source $1; _dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; _sdir=$(dirname "$(readlink -f "$0")"); }; safe_source

# Example usage:
# Run `command` after 10 seconds of idle:
# $0 10 command

idle=false
idleAfter=$(($1 * 1000))
shift

log(){
    echo "`date +"%d.%m.%Y %H:%M"`  : $@"
}

exe_pid=
cleanup(){
    log "Cleaning up"
    [[ -z $exe_pid ]] || kill $exe_pid
}

trap cleanup EXIT

while :; do
    $_sdir/getIdle > /dev/null \
        && break \
        || { \
            log "Waiting for 'getIdle' to become ready..."; \
            sleep 5; \
           }
done

log "Started idle watchdog."
while true; do
  idleTimeMillis=$($_sdir/getIdle)
  #echo $idleTimeMillis  # just for debug purposes.
  if [[ $idle = false && $idleTimeMillis -gt $idleAfter ]] ; then
    log "Computer is now idle."   # or whatever command(s) you want to run...
    "$@" & exe_pid=$!
    wait
    exe_pid=
    idle=true
  fi

  if [[ $idle = true && $idleTimeMillis -lt $idleAfter ]] ; then
    log "end idle"     # same here.
    idle=false
  fi
  sleep 1      # polling interval

done
