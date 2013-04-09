#! /bin/bash
# SCRIPT: tinasync.sh
# AUTHOR: Aaron Smith
# VERSION HISTORY:
# 1.3 - 02/18/2013 - Modified rsync commands to preserve times. Cleaned up logging a bit.
# 1.2 - 02/17/2013 - Added target creation.  Added progress by line to logfile.  Fixed directory overwrite bug.
# 1.1 - 12/19/2012 - Improved sync file logging and added option to provide sync file.
# 1.0 - 12/18/2012 - Initial release.
#
# USAGE: tinasync.sh [-xc] [-v #] [-l logfile] [-s syncfile] source target
#
# Rsyncs source to target one file/directory at a time. Avoid trailing / in source and target declaration.
#
# OPTIONS:
# -v #		Set logging level to # (0-7)
# -x		Enable xtrace
# -c		Enable console logging
# -l <file>	Direct logging to non default file
# -s <file>	Use pregenerated sync file (such as from a previous run of the command)
#
# KNOWN BUGS:
# Time stamp preservation appears to fail on folders which have anything iside them.  This is due to the 'one file/folder' at a time methodology.  No easy fixes apparent, let me know if you come up with one.
#
# Primary variable declaration
#
logfile=/Library/Logs/synctest.log

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
sourcefile=tobegenerated
while getopts 'v:xcl:s:' option
do
  case $option in
    'v') v_option="${OPTARG}" ;; 
    'x') x_option=true
         set -x ;; 
    'c') c_option=true ;; 
    'l') logfile="${OPTARG}" ;;
    's') sourcefile="${OPTARG}" ;;
  esac
done
logverb "-------------Running ${0}-------------" 5
logverb "Before shift - ${OPTIND} option index items, ${#} positional parameters which are ${*}" 7
shift $(( OPTIND - 1 ))
logverb "After shift - ${OPTIND} option index items, ${#} positional parameters which are ${*}" 7
logverb "Sync file is ${sourcefile}" 7

# Main script
#
source="${1}"
destination="${2}"
# Testing for target and creating as needed
#
if [[ ! -d "${destination}" ]]
then
  logverb "Target directory, ${destination}, does not exist.  Attempting to create..." 6
  mkdir "${destination}" && logverb "...${destination} created" 6 || logverb "...unable to create ${destination}, this will end poorly" 6
fi
# Generating file list for syncing
#
if [[ "${sourcefile}" = "tobegenerated" ]]
then
  syncdate=$(date -j -f "%a %b %d %T %Z %Y" "`date`" "+%s")
  sourcefile="sync${syncdate}.tmp"
  logverb "Generating sync file ${sourcefile}" 5
  ls -R1 "${source}" > "${sourcefile}"
else
  logverb "Using supplied sync file ${sourcefile}" 5
fi
# Setting up progress tracking
#
howbig="$(wc -l ${sourcefile} | awk '{ print $1 }')"
logverb "Syncfile has ${howbig} lines" 5 
# And now we sync
#
for (( progress=0; progress < howbig; progress++ ))
do
  read line
  logverb "Line ${progress} of ${howbig}" 5
  logverb "Line is ${line}" 7
  finalsource="${source}${sourcetemp#${source}}/${line}"
  finaldestination="${destination}${sourcetemp#${source}}/${line}"
  logverb "Final source is ${finalsource} and final destination is ${finaldestination}" 7
  if [[ "${line}" = ${source}*: ]]
  then
    logverb "Appears to be a directory, storing path ${line}" 7
    sourcetemp="${line%:}"
    logverb "Stored path is ${sourcetemp}" 7
  elif [[ "${line}" = "" ]]
  then
    logverb "Ignoring blank line" 6
  elif [[ -f "${finalsource}" ]]
  then
    logverb "Syncing file ${finalsource} to ${finaldestination}" 5
    rsync -pogEdt "${finalsource}" "${finaldestination}"
  elif [[ -d "${finalsource}" ]]
  then
    if [[ ! -d "${finaldestination}" ]]
    then
      logverb "Syncing directory ${finalsource} to ${finaldestination}" 5
      rsync -pogEdt "${finalsource}" "${finaldestination}"
    else
      logverb "Directory ${finaldestination} already exists, skipping" 5
    fi
  else
    logverb "Not syncing ${finalsource}" 4
  fi
  logverb "-EOL" 7
done < "${sourcefile}"

logverb "----------FINISHED----------" 5

exit 0
