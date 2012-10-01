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
#    This is a standalone script to set up an AUT
# on a set of machines for replaying testcases.
#
# Machines required:
#
#    - "local" machine to run this script
#    - "stage" machine to stage the configuration
#    - "remote" machine(s) to set up the AUT
#
# Requirements on "local":
#
#    - Directory containing this script
#    - svn
#
# Requirements on "remote":
#
#      jdk
#      ant 
#      xvfb
#
# SSH requirements
#
#    - local machine to stage and remote machine
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
#    $tmpdirtag
#    $stage_host $host_list $username
#    $x_lib_path $cmd_xvfb
#------------------------------
aut_name=$1
hostcfg=$2

if [ -z $aut_name ] || [ -z $hostcfg ]
then
   echo "Usage: $0 <AUT Name> <host config file>"
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


#------------------------------
# Configuration variables 
#------------------------------
local_root_dir=$(readlink -f $local_root_dir)


#------------------------------
# Setup tools on staging and remote host
#------------------------------

echo "*** BEGIN Setting up cluster for testcase execution ***"

#
# Check out scripts
#
echo "*** CS 1/10 Checking out tool scripts on stage and remote machines ***"

action="rm -rf $root_dir ; mkdir -p $dozen_dir ; svn co --non-interactive --trust-server-cert --quiet https://svn.cs.umd.edu/repos/guitar/dozen $dozen_dir"
do_action_bg $username $stage_host "$action"
do_action_host_list "$action"
ret=$?
if [ $ret -ne 0 ]
then
   echo FAILED $ret
   exit $ret
fi
# Just in case
wait

#
# Install tools 
#
echo "*** CS 2/10 Building tool scripts on stage and remote machines ***"

action="$dozen_dir/tools/scripts/main.sh $guitar_revision $checkout_type"
do_action_bg $username $stage_host "$action"
do_action_host_list "$action"
ret=$?
if [ $ret -ne 0 ]
then
   echo FAILED $ret
   exit $ret
fi
# Just in case
wait

#------------------------------
# Set up AUT on staging machine
#------------------------------

# Dozen directory already cleaned above

#
# Init dirs
#
echo "*** Initialising $aut_name directory structure ***"
action="$common_dir/common-init-dir.sh $aut_name"
do_action $username $stage_host "$action"
ret=$?
if [ $ret -ne 0 ]
then
   exit $ret
fi

#
# Check out the AUT from Internet
#
echo "*** CS 3/10 Check out $aut_name from source on staging machine ***"
action="$common_dir/common-checkout.sh $aut_name"
do_action $username $stage_host "$action"
ret=$?
if [ $ret -ne 0 ]
then
   exit $ret
fi

#
# Build AUT
#
echo "*** CS 4/10 Building $aut_name on staging machine ***"
action="$common_dir/common-build.sh $aut_name"
do_action $username $stage_host "$action"
ret=$?
if [ $ret -ne 0 ]
then
   exit $ret
fi

#
# Instrument aut 
#
echo "*** CS 5/10 Instrumenting $aut_name on staging machine ***"
action="$common_dir/common-inst.sh $aut_name"
do_action $username $stage_host "$action"
ret=$?
if [ $ret -ne 0 ]
then
   exit $ret
fi

#
# Rip AUT 
#
echo "*** CS 6/10 Ripping $aut_name on staging machine ***"
action="$common_dir/common-rip.sh $aut_name /tmp/$tmpdirtag $x_lib_path $cmd_xvfb"
do_action $username $stage_host "$action"
ret=$?
if [ $ret -ne 0 ]
then
   exit $ret
fi

#
# Convert GUI to EFG
#
echo "*** CS 7/10 Converting GUI to EFG on staging machine ***"
action="$common_dir/common-gui2efg.sh $aut_name $efg_arg_type"
do_action $username $stage_host "$action"
ret=$?
if [ $ret -ne 0 ]
then
   exit $ret
fi

#
# Copy AUT artifacts (bin, model etc) back to
# the local host 
#
echo "*** CS 8/10 Copying from staging machine to local machine ***"
exec_cmd "rm -rf $local_root_dir"
exec_cmd "mkdir -p $local_root_dir"

RSYNC_CMD_EXCLUDE="--exclude .svn" 
rsync_cmd_b $username $stage_host $aut_root_dir $local_root_dir

#------------------------------
# Set up AUT on remote machines
#------------------------------

# Dozen directory already cleaned above

#
# Distribute AUT artifacts (bin, model etc)
# to remote machine
#
echo "*** CS 9/10 Copying from local machine to remote machines ***"

# Move to scripts dir 
exec_cmd "pushd $local_root_dir"

for host in ${host_list[@]}
do
   RSYNC_CMD_EXCLUDE="--exclude .svn --exclude coverage --exclude logs --exclude oracles --exclude testsuites/* --exclude aut/src/*"
   rsync_cmd_a ./$aut_name/ $username $host $aut_root_dir
done
ret=0
FAIL=0
for job in `jobs -p`
do
   wait $job
   ret=$?
   if [ $ret -ne 0 ] && [ $ret -ne 127 ]
   then
      FAIL=$ret
   fi
done

exec_cmd "popd"
if [ $FAIL -ne 0 ]
then
   echo FAILED $FAIL
   exit $FAIL
fi

#
# Verify AUT binary on remote machines
#
echo "*** CS 10/10 Verifying remote machines ***"
ret=0

# Move to scripts dir 
exec_cmd "pushd $local_root_dir"

action="$common_dir/common-build-check.sh $aut_name"
for host in ${host_list[@]}
do
   do_action $username $host "$action"
   if [ $? -ne 0 ]
   then
      ret=$?
      echo FAILED $ret
   fi 
done 

exec_cmd "popd"

echo "status = $ret"
echo "*** DONE Setting up cluster for testcase execution ***"

exit $ret
