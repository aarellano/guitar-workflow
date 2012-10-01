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

#---------------------------------------------------
# Description:
#
#    This is a standalone script to test if remote
# machines are alive and ssh-able.
#
# Machines required:
#
#    - "local" machine to run this script
#    - "remote" machine(s) to set up the AUT
#
# Requirements on "local":
#
#    - Directory containing this script
#
# Requirements on "remote":
#
#   - Local host
#      svn
#
#   - Remote host
#      jdk
#      ant 
#      xvfb
#
# SSH requirements:
#    - local machine to remote machine(s)
#
# By   baonn@cs.umd.edu
# Date:    06/08/2011
#---------------------------------------------------

#------------------------------
# Script configuration
#
# $1 provides:
#
#    $host_list
#    $username
#
# $2 is the command to be executed
#------------------------------
hostcfg=$1
cmd="$2"

if [ -z $hostcfg ] || [ -z $cmd ]
then
   echo "Usage: $0 <host-config-file> <cmd>"
   exit 1
fi

# Remote host configuration file
source $hostcfg

#
# Should not source common.cfg
#
source "`dirname $0`/util.sh"

if [ -z $host_list ] || [ -z $username ]
then
   echo "host_list username not specified in <host config file>"
   exit 1
fi

#------------------------------
# Run user command on all hosts
#------------------------------
echo "*** Skipping offline machines ***"
for host in ${host_offline_list[@]}
do
   echo OFFLINE $host
done

echo "*** Executing on active machines ***"
ret=0
for host in ${host_list[@]}
do
   ssh_cmd $username $host "$cmd"
   r=$?

   if [ $r -ne 0 ]
   then
      echo FAILED $host
      ret=1
   fi
done
if [ $ret -ne 0 ]
then
   echo FAILED $cmd
fi

exit $ret
