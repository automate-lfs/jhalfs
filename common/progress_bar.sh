#!/bin/bash

# $Id$

set -e

# Be sure that we know the taget name
[[ -z $1 ]] && exit
TARGET=$1  # Remember the target build we are looking for

declare -r  CSI=$'\e['  # DEC terminology, Control Sequence Introducer
declare -r  CURSOR_OFF=${CSI}$'?25l'
declare -r  CURSOR_ON=${CSI}$'?25h'
declare -r  ERASE_LINE=${CSI}$'2K'
declare -r  FRAME_OPEN=${CSI}$'2G['
declare -r  FRAME_CLOSE=${CSI}$'63G]'
declare -r  TS_POSITION=${CSI}$'65G'
declare -a  RESET_LINE=${CURSOR_OFF}${ERASE_LINE}${FRAME_OPEN}${FRAME_CLOSE}

declare -a  GRAPHIC_STR="| / - \\ + "
declare -i  MIN=0  # Start value for minutes
declare -i  SEC=0  # Seconds accumulator
declare -i  POS=0  # Start value for seconds/cursor position

write_or_exit() {
    # make has been killed or failed or run to completion, leave
  if ! fuser -v . 2>&1 | grep make >/dev/null ; then
     echo -n "${CURSOR_ON}" && exit
  fi
    # Target build complete, leave. If we are here, make is alive and a new
    # package target may has been started. Close this instance of the script.
    # The cursor will be restored by echo-finished in makefile-functions.
  [[ -f ${TARGET} ]] && exit
    # It is safe to write to the screen
  echo -n "$1"
}

  # This will loop forever.. or overflow, which ever comes first :)
for ((MIN=0; MIN >= 0; MIN++)); do
  write_or_exit "${RESET_LINE}${TS_POSITION}${MIN} min. 0 sec. "
  # Count the seconds
  for ((SEC=1, POS=3; SEC <= 60; SEC++, POS++)); do
    for GRAPHIC_CHAR in ${GRAPHIC_STR} ; do
      write_or_exit "${CSI}${POS}G${GRAPHIC_CHAR}"
      sleep .2
    done
      # Display the accumulated time.
    write_or_exit "${TS_POSITION}${MIN} min. ${SEC} sec. "
  done
done
exit

