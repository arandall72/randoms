#! /bin/bash
# SCRIPT: moveafter.sh
# Author: Aaron Smith
#
# Finds and moves files/folders older than a set age
#
# VERSION HISTORY:
# 1.0 - 03/03/2013 - Forked from deleteold.sh
# 1.1 - 03/19/2013 - fixed array bug
# 1.2 - 03/21/2013 - added inventory creation section
# 1.4 - 03/27/2013 - added -i option
# 1.5 - 03/28/2013 - combined with delete script
#
# USAGE: moveafter.sh [source directory] [target directory]
#
# OPTIONS:
# -v #          Set logging level to # (0-7)
# -x            Enable xtrace
# -c            Enable console logging
# -l <file>     Direct logging to non default file
# -t <time>     Use specified time rather than default
# -i		Inventory only, do not move
# -r		Delete files instead of moving
#
# Primary variable declaration
#
deltime=30d
logfile=/Library/Logs/moveafter.log
action=move

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
i_option=false
while getopts 'v:xcl:t:ir' option
do
  case $option in
    'v') v_option="${OPTARG}" ;; 
    'x') x_option=true
         set -x ;; 
    'c') c_option=true ;; 
    'l') logfile="${OPTARG}" ;;
    't') deltime="${OPTARG}" ;;
    'i') i_option=true ;;
    'r') action="delete" ;;
  esac
done
logverb "-------------Running ${0}-------------" 5
logverb "Before shift - ${OPTIND} option index items, ${#} positional parameters which are ${*}" 7
shift $(( OPTIND - 1 ))
logverb "After shift - ${OPTIND} option index items, ${#} positional parameters which are ${*}" 7
logverb "inventory option is ${i_option}" 7
logverb "action is ${action}" 7

# Main script
#
deldir="${1}"
destdir="${2}"
logverb "Finding files older than ${deltime} in ${deldir}" 5
dirlist=$(find "${deldir}" -maxdepth 1 -mindepth 1 ! -mtime -"${deltime}")
logverb "Files to be moved or deleted are...${dirlist}" 7
if [[ "${dirlist}" != ""  && "${i_option}" == false ]]
then
  echo "${dirlist}" | while read line
  do
    if [[ "${action}" == "move" ]]
    then
      logverb "Attempting to ${action} ${line}" 6
      mv "${line}" "${destdir}" && logverb "${action} ${line} succeeded" 5 || logverb "${action} ${line} failed" 4
    else
      logverb "Attempting to ${action} ${line}" 6
      rm -r "${line}" && logverb "${action} ${line} succeeded" 5 || logverb "${action} ${line} failed" 4
    fi
  done
fi

# Inventory Creation Section
#
[[ -f "${deldir}/inventory.txt" ]] && (rm "${deldir}/inventory.txt" && logverb "Old inventory file succesfully removed" 6 || logverb "Old inventory file not removed" 6) || logverb "inventory file does not exist" 6
echo -e "-----\nInventory of ${deldir}\nCreated on $(date)\n<folder> - <size> - <modify time> - <creator>\n-----\n" > "${deldir}/inventory.txt"
inventorylist=$(find "${deldir}" -maxdepth 1 -mindepth 1)
echo "${inventorylist}" | while read line
do
  logverb "line is ${line}" 7
  folder="${line##*/}"
  logverb "folder is ${folder}" 7
  creator=$(ls -dl "${line}" | awk '{print $3}')
  logverb "creator is ${creator}" 7
  size=$(du -hd 0 "${line}" | awk '{print $1}')
  logverb "size is ${size}" 7
  age=$(stat -f "%Sm" "${line}")
  logverb "age is ${age}" 7
  logverb "${folder} - ${size} - ${age} - ${creator}" 5
  echo -e "${folder} - ${size} - ${age} - ${creator}" >> "${deldir}/inventory.txt"
done
logverb "-------------Finished-------------" 5
exit 0

