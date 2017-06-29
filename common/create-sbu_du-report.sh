#!/bin/bash
#$Id$

set -e

LOGSDIR=$1
VERSION=$2
DATE=$3

LINE="================================================================================"

# Make sure that we have a directory as first argument
[[ ! -d "$LOGSDIR" ]] && \
  echo -e "\nUSAGE: create-sbu_du-report.sh logs_directory [book_version] [date]\n" && exit

# Make sure that the first argument is a jhalfs logs directory
[[ ! -f "$LOGSDIR"/000-masterscript.log ]] && \
  echo -e "\nLooks like $LOGSDIR isn't a jhalfs logs directory.\n" && exit

# If this script is run manually, the book version may be unknown
[[ -z "$VERSION" ]] && VERSION=unknown
[[ -z "$DATE" ]] && DATE=$(date --iso-8601)

# If there is iteration logs directories, copy the logs inside iteration-1
# to the top level dir
[[ -d "$LOGSDIR"/build_1 ]] && \
  cp $LOGSDIR/build_1/* $LOGSDIR

# Set the report file
REPORT="$VERSION"-SBU_DU-"$DATE".report

[ -f $REPORT ] && : >$REPORT

# Dump generation time stamp and book version
echo -e "\n`date`\n" > "$REPORT"
echo -e "Book version is:\t$VERSION\n" >> "$REPORT"

# If found, dump jhalfs.config file in a readable format
if [[ -f jhalfs.config ]] ; then
  echo -e "\n\tjhalfs configuration settings:\n" >> "$REPORT"
  cat jhalfs.config | sed -e '/parameters/d;s/.\[[013;]*m//g;s/</\t</;s/^\w\{1,6\}:/&\t/' >> "$REPORT"
else
  echo -e "\nNOTE: the jhalfs configuration settings are unknown" >> "$REPORT"
fi

# Dump CPU and memory info
echo -e "\n\n\t\tCPU type:\n" >> "$REPORT"
cat /proc/cpuinfo >> "$REPORT"
echo -e "\n\t\tMemory info:\n" >> "$REPORT"
free >> "$REPORT"

# Parse only that logs that have time data
BUILDLOGS="`grep -l "^Totalseconds:" ${LOGSDIR}/*`"

# Match the first timed log to extract the SBU unit value from it
FIRSTLOG=`grep -l "^Totalseconds:" $LOGSDIR/* | head -n1`
BASELOG=`grep -l "^Totalseconds:" $LOGSDIR/???-binutils* | head -n1`
echo -e "\nUsing ${BASELOG#*[[:digit:]]-} to obtain the SBU unit value."
SBU_UNIT=`sed -n 's/^Totalseconds:\s\([[:digit:]]*\)$/\1/p' $BASELOG`
echo -e "\nThe SBU unit value is equal to $SBU_UNIT seconds.\n"
echo -e "\n\n$LINE\n\nThe SBU unit value is equal to $SBU_UNIT seconds.\n" >> "$REPORT"

# Set the first value to 0 for grand totals calculation
SBU2=0
INSTALL2=0
INSTALLMB2=0

# Start the loop
for log in $BUILDLOGS ; do

# Strip the filename
  PACKAGE="${log#*[[:digit:]]*-}"

# Start SBU calculation
# Build time
  TIME=`sed -n 's/^Totalseconds:\s\([[:digit:]]*\)$/\1/p' $log`
  SECS=`perl -e 'print ('$TIME' % '60')';`
  MINUTES=`perl -e 'printf "%.0f" , (('$TIME' - '$SECS') / '60')';`
  SBU=`perl -e 'printf "%.1f" , ('$TIME' / '$SBU_UNIT')';`

# Append SBU value to SBU2 for grand total
  SBU2=`perl -e 'printf "%.1f" , ('$SBU2' + '$SBU')';`

# Start disk usage calculation
# Disk usage before unpacking the package
  DU1=`grep "^KB: " $log | head -n1 | cut -f1 | sed -e 's/KB: //'`
  DU1MB=`perl -e 'printf "%.3f" , ('$DU1' / '1024')';`
# Disk usage before deleting the source and build dirs
  DU2=`grep "^KB: " $log | tail -n1 | cut -f1 | sed -e 's/KB: //'`
  DU2MB=`perl -e 'printf "%.3f" , ('$DU2' / '1024')';`
# Calculate disk space required to do the build
  REQUIRED1=`perl -e 'print ('$DU2' - '$DU1')';`
  REQUIRED2=`perl -e 'printf "%.3f" , ('$DU2MB' - '$DU1MB')';`

# Append installed files disk usage to the previous entry,
# except for the first parsed log
  if [ "$log" != "$FIRSTLOG" ] ; then
    INSTALL=`perl -e 'print ('$DU1' - '$DU1PREV')';`
    INSTALLMB=`perl -e 'printf "%.3f" , ('$DU1MB' - '$DU1MBPREV')';`
    echo -e "Installed files disk usage:\t\t\t\t$INSTALL KB or $INSTALLMB MB\n" >> $REPORT
    # Append install values for grand total
    INSTALL2=`perl -e 'printf "%.3f" , ('$INSTALL2' + '$INSTALL')';`
    INSTALLMB2=`perl -e 'printf "%.3f" , ('$INSTALLMB2' + '$INSTALLMB')';`
  fi

# Set variables to calculate installed files disk usage
  DU1PREV=$DU1
  DU1MBPREV=$DU1MB

# Dump time and disk usage values
  echo -e "$LINE\n\t\t\t\t[$PACKAGE]\n" >> $REPORT
  echo -e "Build time is:\t\t\t\t\t\t$MINUTES minutes and $SECS seconds" >> $REPORT
  echo -e "Build time in seconds is:\t\t\t\t$TIME" >> $REPORT
  echo -e "Approximate SBU time is:\t\t\t\t$SBU" >> $REPORT
  echo -e "Disk usage before unpacking the package:\t\t$DU1 KB or $DU1MB MB" >> $REPORT
  echo -e "Disk usage before deleting the source and build dirs:\t$DU2 KB or $DU2MB MB" >> $REPORT
  echo -e "Required space to build the package:\t\t\t$REQUIRED1 KB or $REQUIRED2 MB" >> $REPORT

done

# For printing the last 'Installed files disk usage', we need to 'du' the
# root dir, excluding the jhalfs directory (and lost+found). We assume
# that the rootdir is $LOGSDIR/../..
DU1=`du -skx --exclude=jhalfs --exclude=lost+found $LOGSDIR/../.. | cut -f1`
DU1MB=`perl -e 'printf "%.3f" , ('$DU1' / '1024')';`
INSTALL=`perl -e 'print ('$DU1' - '$DU1PREV')';`
INSTALLMB=`perl -e 'printf "%.3f" , ('$DU1MB' - '$DU1MBPREV')';`
echo -e "Installed files disk usage:\t\t\t\t$INSTALL KB or $INSTALLMB MB\n" >> $REPORT
# Append install values for grand total
INSTALL2=`perl -e 'printf "%.3f" , ('$INSTALL2' + '$INSTALL')';`
INSTALLMB2=`perl -e 'printf "%.3f" , ('$INSTALLMB2' + '$INSTALLMB')';`

# Dump grand totals
echo -e "\n$LINE\n\nTotal time required to build the system:\t\t$SBU2  SBU" >> $REPORT
# Total disk usage: including /tools but not /sources.
echo -e "Total Installed files disk usage:\t\t\t$INSTALL2 KB or $INSTALLMB2 MB" >> $REPORT
