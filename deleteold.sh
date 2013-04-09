#! /bin/bash
# SCRIPT: deleteold.sh
# Author: Aaron Smith
# Finds and delete files/folders older than a set age
# USAGE: deleteold.sh [directory] [time]
# -v # for verbose logging, -x for xtrace, -c for console logging, -l <file> to direct logging to a different file

# Primary variable declaration
#
deltime=30d
logfile=/Library/Logs/delold.log

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
while getopts 'v:xcl:t:' option
do
  case $option in
    'v') v_option="${OPTARG}" ;; 
    'x') x_option=true
         set -x ;; 
    'c') c_option=true ;; 
    'l') logfile="${OPTARG}" ;;
    't') deltime="${OPTARG}" ;;
  esac
done
logverb "-------------Running ${0}-------------" 5
logverb "Before shift - ${OPTIND} option index items, ${#} positional parameters which are ${*}" 7
shift $(( OPTIND - 1 ))
logverb "After shift - ${OPTIND} option index items, ${#} positional parameters which are ${*}" 7

# Main script
#
deldir="${1}"
logverb "Finding files older than ${deltime} in ${deldir}" 5

s_index=0
for line in $(find "${deldir}" -maxdepth 1 -mindepth 1 ! -mtime -"${deltime}")
do
  tobedel["${s_index}"]="${line}"
  (( s_index++ ))
done

logverb "Found ${#tobedel[*]} items" 6
logverb "items are ${tobedel[*]}"
for (( d_index = 0; d_index < "${#tobedel[*]}"; d_index++ ))
do
  logverb "Attempting to delete ${tobedel[$d_index]}"
  logverb "Delete index is ${d_index} and count is ${#tobedel[*]}"
#  logverb "THIS WOULD HAVE BEEN DELETED ${tobedel[${d_index}]}" 5 && logverb "Deleted ${tobedel[$d_index]}" 5 || logverb "Failed to delete ${tobedel[$d_index]}" 5
  rm -R  "${tobedel[${d_index}]}" && logverb "Deleted ${tobedel[$d_index]}" 5 || logverb "Failed to delete ${tobedel[$d_index]}" 5
done
size=$( du -hd 0 "${deldir}" | awk '{print $1}' )
logverb "${deldir} is currently ${size}" 5
logverb "-------------Finished-------------" 5
exit 0

