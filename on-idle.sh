#!/bin/bash
set -eu -o pipefail
safe_source () { [[ ! -z ${1:-} ]] && source $1; _dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; _sdir=$(dirname "$(readlink -f "$0")"); }; safe_source

# Example usage:
# Run `command` after 10 seconds of idle:
# $0 10 command

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

idleBase=0 # milliseconds, the offset
idleTimeMsNew=
log "Started idle watchdog. Timeout is: $(format_seconds $idleAfter)"
while true; do
  idleTimeMsNew=$($_sdir/getIdle)
  if [[ -n ${idleTimeMs:-} ]]; then 
    if [[ $idle = false && $idleTimeMsNew -lt $idleTimeMs ]]; then
      sleep 1
      if [[ $($_sdir/getIdle) -gt 500 ]]; then 
        idleBase=$(($idleBase + $idleTimeMs))
        log "!!! adding offset by ${idleTimeMs}ms, total: $(($idleBase / 1000))s"
      else
        idleBase=0
      fi
    fi 
  fi 
  idleTimeMs=$idleTimeMsNew
  #echo $idleTimeMillis  # just for debug purposes.
  if [[ $idle = false && $(($idleTimeMs + $idleBase)) -gt $idleAfterMs ]] ; then
    log "Computer is now idle. (after $(format_seconds $idleAfter))"   # or whatever command(s) you want to run...
    "$@" & exe_pid=$!
    wait
    exe_pid=
    idle=true
  fi

  if [[ $idle = true && $(($idleTimeMs + $idleBase)) -lt $idleAfterMs ]] ; then
    log "end idle"     # same here.
    idle=false
  fi
  sleep 1      # polling interval

done
