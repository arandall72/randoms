#! /bin/bash
# SCRIPT: extents-test.sh
# Author: Aaron Smith
#
# Uses an extents file to measure fragmentation levels.
#
# VERSION HISTORY:
# 0.1 - 03/24/2013 - Forked from moveafter.sh
#
# USAGE: extents-test.sh <extents file>
#
# OPTIONS:
# -v #          Set logging level to # (0-7)
# -x            Enable xtrace
# -c            Enable console logging
# -l <file>     Direct logging to non default file
#
# Primary variable declaration
#
logfile=/Library/Logs/extents-test.log

# Logging function
# Usage: logverb message [severity]
#        Make sure to "quote" the message, severity is per RFC 5424 and indicates what severity to tag the message and defaults to 7
#
logverb () {
  severity="${2:-7}"
  [[ -f "${logfile}" ]] || touch "${logfile}"
  [[ "${c_option}" = "true" && ("${v_option}" = "${severity}" || "${v_option}" > "${severity}" ) ]] && echo "$(date):  ${1}" > /dev/tty
  if [[ -w "${logfile}" ]]
  then
    exec 3>>"${logfile}"
    [[ "${v_option}" = "${severity}" || "${v_option}" > "${severity}" ]] && echo "$(date):  ${1}" >&3
    exec 3>&-
    return 0
  else
    echo "Error, log file ( ${logfile} ) is not writable." >&2
    return 1
  fi
}

# Option testing
#
v_option=5
x_option=false
c_option=false
while getopts 'v:xcl:' option
do
  case $option in
    'v') v_option="${OPTARG}" ;; 
    'x') x_option=true
         set -x ;; 
    'c') c_option=true ;; 
    'l') logfile="${OPTARG}" ;;
  esac
done
logverb "-------------Running ${0}-------------" 5
logverb "Before shift - ${OPTIND} option index items, ${#} positional parameters which are ${*}" 7
shift $(( OPTIND - 1 ))
logverb "After shift - ${OPTIND} option index items, ${#} positional parameters which are ${*}" 7

# Main script
#
extfile="${1}"
OIFS="${IFS}"
IFS=","
totalextents=0
errorextents=0
fragextents=0
while read inodevar modevar sizevar bcountvar affinityvar pathvar extcountvar extnumvar poolvar frbvar basevar endvar depthvar breadthvar
do
(( totalextents++ ))
#logverb "inode is ${inodevar}" 6
case "${inodevar}" in
  *Fatal*) continue;;
  Clearing*) (( errorextents++ ))
               continue;;
  *)
    if [[ "${extcountvar}" =~ [0-9]+$ && "${extcountvar}" > "1" ]]
    then
     (( fragextents++ ))
      logverb "${pathvar} has ${extcountvar} extents.  Extent ${extnumvar} is between blocks ${basevar} & ${endvar} " 7
    fi
  ;;
esac
done < "${extfile}"
IFS="${OIFS}"
logverb "${totalextents} total extents.  ${errorextents} errors, and ${fragextents} fragmented extents" 5
logverb "-------------Finished-------------" 5
exit 0

