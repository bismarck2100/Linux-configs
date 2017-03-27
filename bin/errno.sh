#!/bin/sh
### NAME:      errno
###
### VERSION:   1.0
###
### AUTHOR:    Justin Fries (justinf@us.ibm.com)
###
### COPYRIGHT:
### 
### (C) COPYRIGHT International Business Machines Corp. 2008
### All Rights Reserved
### Licensed Materials - Property of IBM
###
### US Government Users Restricted Rights - Use, duplication or
### disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
###
### SYNOPSIS:
###
###  errno Errno
###
###      Errno: The errno name or number to look up
###
###
### DESCRIPTION:
###
### This script looks up errno values on UNIX or Linux systems.  In most
### cases this is in errno.h but some are found in other files.
###
###
### CAVEATS/WARNINGS:
###
### Errno values are not constant across all operating systems.
###
###
### RETURNED VALUES:
###
###   0  - Displayed the errno
###   1  - Failed to find the errno
###
###
### EXAMPLES:
###
### 1. To look up errno 22 on a system:
###
###      errno 22
###
###
### 2. To look up errno ECONNRESET:
###
###      errno ECONNRESET
###


### Display the operating system name, release and chipset.  Construct a
### list of files to search for errno values.  Make sure 'grep' supports 
### the '-w' option since older HP-UX versions did not.

  GREP_OPTS=hw
  unset FILES
  STATUS=0

  case `uname -s` in
      AIX) VRMF=`oslevel -s` 2>/dev/null ||
           VRMF=`oslevel -r` 2>/dev/null ||
           VRMF="`uname -v`.`uname -r`"

           PLATFORM="AIX $VRMF (`uname -p`)"

           FILES=/usr/include/errno.h
           FILES="$FILES /usr/include/sys/errno.h"
           ;;

    HP-UX) if [ ! -x /usr/contrib/bin/machinfo ] ; then
             CHIP=PA-RISC
           else
             /usr/contrib/bin/machinfo 2>/dev/null |
               grep -i PA-RISC 1>/dev/null 2>&1 && CHIP=PA-RISC
           fi

           echo " foo " | grep -w foo 1>/dev/null 2>&1 || GREP_OPTS=h

           PLATFORM="HP-UX `uname -r` (${CHIP:=Itanium})"

           FILES=/usr/include/errno.h
           FILES="$FILES /usr/include/sys/errno.h"
           FILES="$FILES /usr/include/.unsupp/sys/_errno.h"
           ;;

    Linux) if [ -x /usr/bin/lsb_release ] ; then
             DIST=`/usr/bin/lsb_release -sd 2>/dev/null | tr -d \"`
           elif [ -r /etc/redhat-release ] ; then
             DIST=`head -1 /etc/redhat-release 2>/dev/null`
           elif [ -r /etc/SuSE-release ] ; then
             DIST=`head -1 /etc/SuSE-release 2>/dev/null`
           elif [ -r /etc/UnitedLinux-release ] ; then
             DIST=`head -1 /etc/UnitedLinux-release 2>/dev/null`
           else
             DIST=`cat /etc/*-release 2>/dev/null | head -1`
           fi

           PLATFORM="${DIST:=unknown Linux (`uname -m`, `uname -r`)}"

           FILES=/usr/include/errno.h
           FILES="$FILES /usr/include/asm/errno.h"
           FILES="$FILES /usr/include/asm-*/errno.h"
           FILES="$FILES /usr/include/asm-generic/errno-base.h"
           FILES="$FILES /usr/include/bits/errno.h"
           FILES="$FILES /usr/include/linux/errno.h"
           FILES="$FILES /usr/include/sys/errno.h"
           ;;

    SunOS) PLATFORM="Solaris `uname -r | sed 's/5\.//'` (`uname -p`)"

           FILES=/usr/include/errno.h
           FILES="$FILES /usr/include/sys/errno.h"
           ;;

        *) printf "* System `uname -s` not supported\n"
           exit 1
           ;;
  esac


### Either print a syntax error or look up each errno.  First, uppercase
### the search argument and find it in a system header.  Filter out only
### preprocessor defines, then remove the #define and any leading spaces
### or tabs and make sure the name begins with E.  Display results which
### match the user errno name or value, but try to filter duplicates out
### (some systems #define things more than once).  If the search results
### are empty, print an error message to that effect.

  case $# in
    0) printf "syntax: errno Number\n"
       exit 1
       ;;

    *) printf "Errno lookup on $PLATFORM:\n"

       for ARG in $@; do
         SEARCH=`echo $ARG | tr '[:lower:]' '[:upper:]'`
         grep -$GREP_OPTS $SEARCH $FILES 2>/dev/null |
           grep 'define' | sed 's/.*define *//' |
           sed 's/^	*//' | grep '^E' |
           while read ERRNAME ERRVAL ERRDESC; do
             if [ $SEARCH = $ERRNAME ] ; then
               printf "  %-16s %-4s $ERRDESC\n" $ERRNAME $ERRVAL
             elif [ $SEARCH = $ERRVAL ] ; then
               printf "  %-16s %-4s $ERRDESC\n" $ERRNAME $ERRVAL
             fi
           done | uniq | grep '^  E' || {
             printf "* Errno $SEARCH not found.\n"
             SEARCH=1
           }
        done
        ;;
  esac


### Exit nicely.

  exit $STATUS

