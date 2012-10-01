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
#    This is a standalone script to copy testsuite
# to remote machines from a testsuite distribution
# source.
#
#    If distribution source is specified as NULL then 
# local machine is used.
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
# SSH requirements
#
#    - local machine to remote machine(s)
#    - remote machine(s) to distribution source
#
# By   baonn@cs.umd.edu
# Date:    06/08/2011
#---------------------------------------------------

#------------------------------
# Script configuration
#
# $1 is the AUT name
#
# $2 provides:
#
#    $host_list
#    $username
#------------------------------
aut_name=$1
hostcfg=$2
archive_username=$3
archive_hostname=$4
archive_auts_dir=$5
testsuite_name=$6


if [ -z $aut_name ] || [ -z $hostcfg ] || [ -z $archive_username  ] || [ -z $archive_hostname ] || [ -z $archive_auts_dir ] || [ -z $testsuite_name ]
then
   echo "Usage: $0 <AUT Name> <host-config-file> <archive-username> <archive-hostname> <archive-auts-dir> <testsuite-name>"
   exit 1
fi

# Loads $username $host_list
source $hostcfg

#
# Should not source common.cfg
#
# Requires $tmpdirtag from $hostcfg
#
source "`dirname $0`/util.sh"
source "`dirname $0`/cluster-utils.sh"
source "`dirname $0`/cluster.cfg"

if [ -z $host_list ] || [ -z $username ] || [ -z $testsuites_dir ]
then
   echo "host_list username testsuites_dir not specified in <host config file>"
   exit 1
fi

#------------------------------
# Distribute testcases
#------------------------------
echo "*** Distributing testcases to remote machines ***"
i=0
ret=0
for host in ${host_list[@]}
do
   t=$testsuites_dir/$testsuite_name.$i

   if [ $archive_username != "NULL" ] && [ $archive_hostname != "NULL" ]
   then
      #
      # If archive_username + archive_hostname is specified
      # then pull testsuite from there into remote hosts
      #

      #
      # The command below works with no "port" in $archive_hostname
      #
      action="rm -rf $t ; mkdir -p $t ; $common_dir/util-rsync.sh $archive_username@$archive_hostname:$archive_auts_dir/$aut_name/testsuites/$testsuite_name.$i  $testsuites_dir"

      do_action $username $host "$action"
      ret=$?
      if [ $ret -ne 0 ]
      then
         exit $ret
      fi
   else
      #  
      # Push from local machine ($archive_auts_dir) to remote hosts 
      # 
      rsync_cmd_a $archive_auts_dir/$aut_name/testsuites/$testsuite_name.$i $username $host $testsuites_dir
   fi

   i=$((i+1))
done
if [ $ret -ne 0 ]
then
   echo FAILED rsync $ret
   exit $ret
fi

echo "*** Verifying testcases on remote machines ***"
i=0
total=0
for host in ${host_list[@]}
do
   t=$testsuites_dir/$testsuite_name.$i
   action="ls -lR $t | grep tst | wc -l"

   stdout="TO-BE-OVERWRITTEN"
   do_action_w_stdout $username $host "$action"
   ret=$?
   if [ $ret -ne 0 ]
   then
      echo FAILED verify testcase $ret
      exit $ret
   fi

   total=$((total+$stdout))

   i=$((i+1))
done
echo $total

exit $ret
