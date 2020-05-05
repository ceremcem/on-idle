#!/bin/bash
set -eu -o pipefail
safe_source () { [[ ! -z ${1:-} ]] && source $1; _dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; _sdir=$(dirname "$(readlink -f "$0")"); }; safe_source

# Example usage:
# Run `command` after 10 seconds of idle:
# $0 10 command

idle=false
idleAfter=$(($1 * 1000))
shift

while true; do
  idleTimeMillis=$($_sdir/getIdle)
  #echo $idleTimeMillis  # just for debug purposes.
  if [[ $idle = false && $idleTimeMillis -gt $idleAfter ]] ; then
    echo "start idle"   # or whatever command(s) you want to run...
    $@ 
    idle=true
  fi

  if [[ $idle = true && $idleTimeMillis -lt $idleAfter ]] ; then
    echo "end idle"     # same here.
    idle=false
  fi
  sleep 1      # polling interval

done
