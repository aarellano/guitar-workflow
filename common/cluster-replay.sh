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

#-------------------------------------------------
# Description:
#
#    Script to replay testcases on a cluster and
# archive the results on an archive location.
#
# Enviroment setup requirements
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
#   - local machine to remote machine(s)
#   - remote machine(s) to archive machine(s)
#   - local machne to all archive machine
#   - first archive machine to other archive machines
#
# By   baonn@cs.umd.edu
# Date:    06/08/2011
#-------------------------------------------------

#------------------------------
# Script configuration
#
# $1 is the AUT name
#
# $2 provides:
#
#    $tmpdirtag
#    $stage_host $host_list $username
#    $x_lib_path $cmd_xvfb
#------------------------------
aut_name=$1
hostcfg=$2
archive_username=$3
archive_hostlist=$4
archive_auts_dir=$5
testsuite_name=$6

if [ -z $aut_name ] || [ -z $hostcfg ] || [ -z $archive_username ] || [ -z "$archive_hostlist" ] || [ -z "$archive_auts_dir" ] || [ -z "$testsuite_name" ]
then
   echo "Usage: $0 <AUT Name> <host-config-file> <archive-username> <archive-hostlist> <archive-auts-dir> <testsuite-name>"
   echo ""
   echo "<archive-hostlist> = ':' separated list of archive hosts. Results will be archived to the first host. Rest are temporary stores."
   exit 1
fi

# Remote host config file
source $hostcfg

#
# Should not source common.cfg
#
# Requires $tmpdirtag,
#          $stage_host, $host_list, $username,
#          $x_lib_path, $cmd_xvfb from $hostcfg
#
source "`dirname $0`/util.sh"
source "`dirname $0`/cluster-utils.sh"
source "`dirname $0`/cluster.cfg"

if [ -z $tmpdirtag ] || [ -z $stage_host ] || [ -z $host_list ] || [ -z $username ] || [ -z $x_lib_path ] || [ -z $cmd_xvfb ]
then
   echo "tmpdirtag=$tmpdirtag stage_host=$stage_host host_list=$host_list username=$username x_lib_path=$x_lib_path cmd_xvfb=$cmd_xvfb not specified in <host config file>"
   exit 1
fi

#
# Folowing are derived variables from cluster.cfg which are required
#
if [ -z "$testsuites_dir" ]
then
   echo "testsuites_dir not defined in cluster.cfg"
   exit 1
fi


#
# Create an array from the input $host_list
#

# Replace ":" with " "
archive_hostlist=`echo "$archive_hostlist" | awk 'BEGIN{FS=":"}{for (i=1; i<=NF; i++) print $i}'`

# Count number of archive hosts
num_archive_host=0
archive_hostname[0]=""
for ah in $archive_hostlist
do
   archive_hostname[$num_archive_host]=$ah
   num_archive_host=$((num_archive_host + 1))
done

echo "*** Replaying testcases ***"
echo "Replaying on ${#host_list[@]} remote machines"
echo "Temporary archive on $num_archive_host machines"

#
# Clear testsuite directory on archive hosts
# Archive location:
#
# $archive_auts_dir/$aut_name/testsuites/$testsuite_name*
#
# will be first cleared. Content will be filled during
# replay.
#
# Serial execution
#
echo "*** Clearing archive directories ***"
for ah in $archive_hostlist
do
   action="rm -rf $archive_auts_dir/$aut_name/testsuites/$testsuite_name* ; mkdir -p $archive_auts_dir/$aut_name"
   do_action $archive_username $ah "$action"
   ret=$?
   if [ $ret -ne 0 ]
   then
      echo FAILED clearing $ah
      exit $ret
   fi
done
echo "*** DONE Clearing archive directories ***"


#
# Execute common-replay.sh on remote machine. Assign temporary archive
# to each remote machine in round robin manner.
#
# Parallel execution
#
i=0
n=0
pidlist=""
started=0
for host in ${host_list[@]}
do
   chunk=$testsuite_name.$i

   action="$common_dir/common-replay.sh $aut_name $gui_file $efg_file $testsuites_dir $chunk /tmp/$tmpdirtag $x_lib_path $cmd_xvfb $archive_username ${archive_hostname[$n]} $archive_auts_dir"

   do_action_bg $username $host "$action"

   i=$((i+1))
   pidlist="$pidlist $!"
   started=$((started+1))

   n=$((n+1))
   if [ $n -ge $num_archive_host ]
   then
      n=0
   fi
done
ret=0
collected=0
for job in $pidlist
do
   wait $job
   localret=$?

   if [ $localret -ne 0 ]
   then
      echo FAILED Job $job returned $localret
      ret=1
   fi

   if [ $localret -eq 0 ]
   then
      collected=$((collected+1))
   fi
done
echo Collected $collected/$started processes
if [ $ret -ne 0 ]
then
   FAILED Execution in one or more remote machines
   exit 1
fi

#
# Copy from temporary archive hostname(s) to
# the first archive hostname
#
# Serial execution
#
ret=0
echo "*** Copying results to archive machine ***"
echo "archive_hostname is " ${archive_hostname[@]} 
for ah in ${archive_hostname[@]}
do
   echo "Inside that for loop"
   echo "ah is " $ah
   if [ "$ah" != "${archive_hostname[0]}" ]
   then
      echo "Inside the if statement"
      cmd="rsync -avz -e \"ssh -o StrictHostKeyChecking=no \" $archive_username@$ah:$archive_auts_dir/$aut_name/testsuites/$testsuite_name $archive_auts_dir/$aut_name/testsuites"
      echo "The command is" $cmd
      do_action $archive_username ${archive_hostname[0]} "$cmd"

      ret=$?
      if [ $ret -ne 0 ]
      then
         echo FAILED $ret
         break
      fi
   fi
done
echo "*** DONE Copying results to archive machine ***"


echo "*** DONE Replaying testcases ***"

exit $ret
