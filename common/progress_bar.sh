# shellcheck shell=bash
# $Id$

set -e

# Be sure that we know the target name
[[ -z $1 ]] && exit
TARGET=$1  # Remember the target build we are looking for
MAKE_PPID=$2

declare -r  CSI=$'\e['  # DEC terminology, Control Sequence Introducer
declare -r  CURSOR_OFF=${CSI}$'?25l'
declare -r  CURSOR_ON=${CSI}$'?25h'
declare -r  ERASE_LINE=${CSI}$'2K'
declare -r  FRAME_OPEN=${CSI}$'2G['
declare -r  FRAME_CLOSE=${CSI}$'63G]'
declare -r  TS_POSITION=${CSI}$'65G'
declare -r  RESET_LINE=${CURSOR_OFF}${ERASE_LINE}${FRAME_OPEN}${FRAME_CLOSE}

declare -r  GRAPHIC_STR="| / - \\ + "
declare -i  SEC=0  # Seconds accumulator
declare -i  PREV_SEC=0

# Prevent segfault on stripping phases
if [[ "$BASHBIN" = "/tools/bin/bash" ]] ; then
  SLEEP=/tools/bin/sleep
elif [ -x /bin/sleep ] ; then
  SLEEP=/bin/sleep
else
  SLEEP=/usr/bin/sleep
fi

write_or_exit() {
    # make has been killed or failed or run to completion, leave
  [[ ! -e /proc/${MAKE_PPID} ]] && echo -n "${CURSOR_ON}" && exit

    # Target build complete, leave.
  [[ -f ${TARGET} ]] && echo -n "${CURSOR_ON}" && exit

    # It is safe to write to the screen
  echo -n "$1"
}

  # initialize screen
write_or_exit "${RESET_LINE}${TS_POSITION}0 min. 0 sec"

  # loop forever..
while true ; do

    # Loop through the animation string
  for GRAPHIC_CHAR in ${GRAPHIC_STR} ; do
    write_or_exit "${CSI}$((SEC + 3))G${GRAPHIC_CHAR}"
    $SLEEP .12 # This value MUST be less than .2 seconds.
  done

    # A BASH internal variable, the number of seconds the script
    # has been running. modulo convert to 0-59
  SEC=$((SECONDS % 60))

    # Detect rollover of the seconds.
  (( PREV_SEC > SEC )) && write_or_exit "${RESET_LINE}"
  PREV_SEC=$SEC

    # Display the accumulated time. div minutes.. modulo seconds.
  write_or_exit "${TS_POSITION}$((SECONDS / 60)) min. $SEC sec"
done

exit
