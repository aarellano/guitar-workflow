#!/bin/bash
# 
# xvfb start/stop Xvfb server
#
# Written by Bao N. Nguyen (2010)

case "$1" in
'start')

   DISPLAY_NUMBER=$2 
   SESSION_DIR=$3
   export LD_LIBRARY_PATH=$4
   CMD_XVFB=$5

   if [ -z $DISPLAY_NUMBER ]
   then
     echo "No DISPLAY_NUMBER. Exiting."
     exit 1
   fi

   if [ -z $SESSION_DIR ] 
   then
     echo "No SESSION_DIR. Exiting."
     exit 1
   fi
 
   if [ ! -e $SESSION_DIR ]
   then
      mkdir $SESSION_DIR
   fi


   if [ ! -e $LD_LIBRARY_PATH ]
   then
      echo FAILED Path $LD_LIBRARY_PATH not found
      echo FAILED Machine name `hostname`
      exit 1
   else
      nohup $CMD_XVFB :$DISPLAY_NUMBER -fbdir $SESSION_DIR -screen 0 1600x1200x16 &
      sleep 3
      cat nohup.out

      # Check if lock file was created
      echo Looking for Xvfb lock files for $DISPLAY_NUMBER

      echo /tmp/.X$DISPLAY_NUMBER'-lock' /tmp/.X11-unix/X$DISPLAY_NUMBER
      ls /tmp/.X$DISPLAY_NUMBER'-lock' /tmp/.X11-unix/X$DISPLAY_NUMBER

      if [ $? -ne 0 ]
      then
         echo FAILED Xvfb not started. Lock file not found.
         exit 1
      fi

      echo Xvfb started at display number $DISPLAY_NUMBER 1600x1200x32

   fi
   ;;

'stop')

   DISPLAY_NUMBER=$2 
   if [ -z $2 ]
   then
     echo "No DISPLAY_NUMBER. Exiting."
     exit 1
   fi

   echo stopping Xvfb

   /usr/bin/pkill -x  "(Xvfb)"
   rm -f /tmp/.X$DISPLAY_NUMBER'-lock'
   ls /tmp/.X$DISPLAY_NUMBER'-lock'
   if [ $? -eq 0 ]
   then
     echo FAILED Could not delete .X files
     exit 1
   fi

   rm -f /tmp/.X11-unix/X$DISPLAY_NUMBER
   ls /tmp/.X11-unix/X$DISPLAY_NUMBER
   if [ $? -eq 0 ]
   then
     echo FAILED Could not delete .X files
     exit 1
   fi
   ;;

*)
   echo "Usage: $0 { start [Display number] | stop } <DISPLAY NUMBER> <x-session-dir> <x-lib-path> <cmd-xvfb>"
   exit 1
   ;;
esac

exit 0
