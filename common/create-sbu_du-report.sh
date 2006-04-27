#!/bin/bash
#$Id$

set -e

LOGSDIR=$1
VERSION=$2

# Make sure that we have a directory as first argument
[[ ! -d "$LOGSDIR" ]] && \
  echo -e "\nUSAGE: create-sbu_du-report.sh logs_directory [book_version]\n" && exit

# Make sure that the first argument is a jhalfs logs directory
[[ ! -f "$LOGSDIR"/000-masterscript.log ]] && \
  echo -e "\nLooks like $LOGSDIR isn't a jhalfs logs directory.\n" && exit

# If this script is run manually, the book version may be unknow
[[ -z "$VERSION" ]] && VERSION=unknown

# If there is iteration logs directories, copy the logs inside iteration-1
# to the top level dir
[[ -d "$LOGSDIR"/iteration-1 ]] && \
  cp $LOGSDIR/iteration-1/* $LOGSDIR

# Set the report file
REPORT="$VERSION"-SBU_DU-$(date --iso-8601).report

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

# Parse only that logs that have time dataq
BUILDLOGS=`grep -l "^real\>" $LOGSDIR/*`

# Match the first timed log to extract the SBU unit value from it
BASELOG=`grep -l "^real\>" $LOGSDIR/* | head -n1`
echo -e "\n\nUsing $BASELOG to obtain the SBU unit value." >> "$REPORT"
BASEMINUTES=`grep "^real\>" $BASELOG | cut -f2 | sed -e 's/m.*//'`
BASESECONDS=`grep "^real\>" $BASELOG | cut -f2 | sed -e 's/.*m//;s/s//'`
SBU_UNIT=`echo "scale=3; $BASEMINUTES * 60 + $BASESECONDS" | bc`
echo -e "The SBU unit value is equal to $SBU_UNIT seconds.\n" >> "$REPORT"

# Set the first value to 0 for grand totals calculation
SBU2=0
INSTALL2=0
INSTALLMB2=0

for log in $BUILDLOGS ; do

#Start SBU calculation
  # Build time
  BUILDTIME=`grep "^real\>" $log | cut -f2`
  # Build time in seconds
  MINUTES=`grep "^real\>" $log | cut -f2 | sed -e 's/m.*//'`
  SECS=`grep "^real\>" $log | cut -f2 | sed -e 's/.*m//;s/s//'`
  TIME=`echo "scale=3; $MINUTES * 60 + $SECS" | bc`
  # Calculate build time in SBU
  SBU=`echo "scale=3; $TIME / $SBU_UNIT" | bc`
  # Append SBU value to SBU2 for grand total
  SBU2="$SBU2 + $SBU"

#Start disk usage calculation
  # Disk usage before unpack the package
  DU1=`grep "^KB: " $log | head -n1 | cut -f1 | sed -e 's/KB: //'`
  DU1MB=`echo "scale=2; $DU1 / 1024" | bc`
  # Disk usage before delete sources and build dirs
  DU2=`grep "^KB: " $log | tail -n1 | cut -f1 | sed -e 's/KB: //'`
  DU2MB=`echo "scale=2; $DU2 / 1024" | bc`
  # Calculate disk space required to do the build
  REQUIRED1=`echo "$DU2 - $DU1" | bc`
  REQUIRED2=`echo "scale=2; $DU2MB - $DU1MB" | bc`

  # Append installed files disk usage to the previous entry,
  # except for the first parsed log
  if [ "$log" != "$BASELOG" ] ; then
    INSTALL=`echo "$DU1 - $DU1PREV" | bc`
    INSTALLMB=`echo "scale=2; $DU1MB - $DU1MBPREV" | bc`
    echo -e "Installed files disk usage:\t\t\t\t$INSTALL KB or $INSTALLMB MB\n" >> "$REPORT"
    # Append install values for grand total
    INSTALL2="$INSTALL2 + $INSTALL"
    INSTALLMB2="$INSTALLMB2 + $INSTALLMB"
  fi

  # Set variables to calculate installed files disk usage
  DU1PREV=$DU1
  DU1MBPREV=$DU1MB

  # Append log name
  echo -e "\n\t$log" >> "$REPORT"

  # Dump time values
  echo -e "Build time is:\t\t\t$BUILDTIME" >> "$REPORT"
  echo -e "Build time in seconds is\t$TIME" >> "$REPORT"
  echo -e "Approximate SBU time is:\t$SBU" >> "$REPORT"

  # Dump disk usage values
  echo -e "\nDisk usage before unpack the package:\t\t\t$DU1 KB or $DU1MB MB" >> "$REPORT"
  echo -e "Disk usage before delete sources and build dirs:\t$DU2 KB or $DU2MB MB" >> "$REPORT"
  echo -e "Required space to build the package:\t\t\t$REQUIRED1 KB or $REQUIRED2 MB\n" >> "$REPORT"

done

# Dump grand totals
TOTALSBU=`echo "scale=3; ${SBU2}" | bc`
echo -e "\nTotal time required to build the systen:\t$TOTALSBU SBU\n" >> "$REPORT"
TOTALINSTALL=`echo "${INSTALL2}" | bc`
TOTALINSTALLMB=`echo "scale=2; ${INSTALLMB2}" | bc`
echo -e "Total Installed files disk usage
    (including /tools but not /sources):\t$TOTALINSTALL KB or $TOTALINSTALLMB MB\n" >> "$REPORT"


