#!/bin/bash

#
#  Copyright (c) 2009-@year@. The  GUITAR group  at the University of
#  Maryland. Names of owners of this group may be obtained by sending
#  an e-mail to atif@cs.umd.edu
#
#  Permission is hereby granted, free of charge, to any person obtaining
#  a copy of this software and associated documentation files
#  (the "Software"), to deal in the Software without restriction,
#  including without limitation  the rights to use, copy, modify, merge,
#  publish,  distribute, sublicense, and/or sell copies of the Software,
#  and to  permit persons  to whom  the Software  is furnished to do so,
#  subject to the following conditions:
#
#  The above copyright notice and this permission notice shall be included
#  in all copies or substantial portions of the Software.
#
#  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
#  OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
#  MERCHANTABILITY,  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
#  IN NO  EVENT SHALL THE  AUTHORS OR COPYRIGHT  HOLDERS BE LIABLE FOR ANY
#  CLAIM, DAMAGES OR  OTHER LIABILITY,  WHETHER IN AN  ACTION OF CONTRACT,
#  TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
#  SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#

#------------------------------
# Common functions
#------------------------------

# Execute a remote command in foreground and return status
function do_action {
   u=$1
   h=$2
   a=$3

   ssh_cmd $u $h "$a"

   return $?
}

# Execute a remote command in background 
function do_action_bg {
   u=$1
   h=$2
   a=$3

   ssh_cmd $u $h "$a" &

   return $?
}

# Execute a remote command in foreground and return error status
function do_action_w_stdout {
   u=$1
   h=$2
   a=$3

   if [ -z $stdout ]
   then
      echo FAILED $stdout variable required
      return 1
   fi
   stdout=$(ssh_cmd_q $u $h $a)

   return $?
}

# Execute a command on multiple machines given by $username, $host_list
function do_action_host_list {
   a=$1

   if [ -z $username ] || [ -z $host_list ] || [ -z "$a" ]
   then
      echo "FAILED username host_list action not specified"
      return 1
   fi

   for host in ${host_list[@]}
   do
      do_action_bg $username $host "$a"
   done

   FAIL=0
   for job in `jobs -p`
   do
   echo $job
      wait $job
      ret=$?
      if [ $ret -ne 0 ] && [ $ret -ne 127 ]
      then
         FAIL=1
      fi
   done

   return $FAIL
}
