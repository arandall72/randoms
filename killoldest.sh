#! /bin/bash
# SCRIPT: killoldest.sh
# AUTHOR: Aaron Smith
# VERSION HISTORY:
# 1.2 - 03/08/2013 - Fixed bug where target folder is deleted.  Expanded logging.
# 1.1 - 02/28/2013 - Expanded documentation.  Modified logging levels.
# 1.0 - 02/18/2013 - Initial release.
#
# USAGE: killoldest.sh [-xc] [-v #] [-l logfile] [-p] <target folder> <MB/percent limit>
#
# OPTIONS:
# -v #		Set logging level to # (0-7)
# -x		Enable xtrace
# -c		Enable console logging
# -l <file>	Direct logging to non default file
# -p		Use percentage instead of MB for size limit
#
# Primary variable declaration
#
logfile=/Library/Logs/killoldest.log

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
# Age test function
# Usage: howbig <target>
#        Returns size of target file/folder in Megabytes
#
howbig () {
  echo $(du -ms ${1} | awk '{ print $1 }')
}

# Find oldest function
# Usage: oldest <target>
#        Returns oldest file or folder inside target folder
#
oldest () {
  echo $(ls -rtC ${1} | awk '{ print $1 }')
}

# Drive usage function
# Usage: driveuse <target>
#        Returns current percentage used of filesystem that target lives on
#
driveuse () {
  percuse=$(df "${1}" | grep dev | awk '{ print $5 }')
  echo "${percuse%"%"}"
} 

# Option testing
#
v_option=5
x_option=false
c_option=false
p_option=false
while getopts 'v:xcl:p' option
do
  case $option in
    'v') v_option="${OPTARG}" ;; 
    'x') x_option=true
         set -x ;; 
    'c') c_option=true ;; 
    'l') logfile="${OPTARG}" ;;
    'p') p_option=true ;;
  esac
done
logverb "-------------Running ${0}-------------" 5
logverb "Before shift - ${OPTIND} option index items, ${#} positional parameters which are ${*}" 7
shift $(( OPTIND - 1 ))
logverb "After shift - ${OPTIND} option index items, ${#} positional parameters which are ${*}" 7
logverb "Target directory is ${1}" 7
logverb "Measure by percentage is ${p_option}" 7
logverb "Percent or MB limit is ${2}" 7

# Main script
#
if [[ "${p_option}" = "false" ]]
then
  while (($(howbig "${1}") > "${2}"))
  do
    deleteme="${1}/$(oldest ${1})"
    logverb "Attempting to delete ${deleteme}" 6
    rm -r "${deleteme}" && logverb "Successfully deleted ${deleteme}" 5 || logverb "Failed to delete ${deleteme}" 3
  done
else
  while (($(driveuse "${1}") > "${2}"))
  do
    deleteme="${1}/$(oldest ${1})"
    if [[ "${deleteme}" -ef "${1}" ]]
    then
      logverb "Nothing left to delete but drive is still over ${2}% usage" 7
      break
    else
      logverb "Attempting to delete ${deleteme}" 6
      rm -r "${deleteme}" && logverb "Successfully deleted ${deleteme}" 5 || logverb "Failed to delete ${deleteme}" 3
    fi
  done
fi
logverb "-------------Finished ${0}-------------" 5
exit 0
