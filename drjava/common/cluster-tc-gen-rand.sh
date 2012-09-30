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
#    This is a standalone script to generate
# sequential length coverage testcases using
# a staging cluster machine and store the
# resulting testcases on an archive machine.
#
# Machines required:
#
#    - "local" machine to run this script
#    - "stage" machine to stage the generation
#
# Requirements on "local":
#
#    - Directory containing this script
#    - svn
#
# SSH requirements
#
#    - local machine to staging machine
#    - staging machine to archive machine
#
# By   baonn@cs.umd.edu
# Date:    06/08/2011
#
#
# NOTE: This is almost identical to
#          cluster-tc-gen-sq.sh
#
#       Please keep these two scripts in sync.
#
#---------------------------------------------------

#------------------------------
# Script configuration
#
# $1 is the AUT name
#
# $2 provides:
#
#    $stage_host
#    $username
#------------------------------
aut_name=$1
hostcfg=$2
archive_username=$3
archive_hostname=$4
archive_auts_dir=$5
length=$6
numtc=$7

# Check parameters
if [ -z $aut_name ] || [ -z $hostcfg ] || [ -z $archive_username ] || [ -z "$archive_hostname" ] || [ -z "$archive_auts_dir" ] || [ -z $length ] || [ -z $numtc ]
then
   echo "Usage: $0 <AUT Name> <host-config-file> <archive-username> <archive-hostname> <archive-auts-dir> <length> <# testcases>"
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

# Check loaded vars
if [ -z $tmpdirtag ] || [ -z $stage_host ] || [ -z $guitar_revision ] || [ -z $checkout_type ] || [ -z $efg_arg_type ] || [ -z $username ] || [ -z $x_lib_path ] || [ -z $cmd_xvfb ]
then
   echo "tmpdirtag=$tmpdirtag stage_host=$stage_host guitar_revision=$guitar_revision checkout_type=$checkout_type efg_arg_type=$efg_arg_type  username=$username x_lib_path=$x_lib_path cmd_xvfb=$cmd_xvfb not specified in <host config file>"
   exit 1
fi

#------------------------------
# Configuration variables 
#------------------------------

local_root_dir=$(readlink -f $local_root_dir)

#------------------------------
# Set up archive machine
#------------------------------

#
# Create archive directory
#
do_action $archive_username $archive_hostname "rm -rf $archive_auts_dir/$aut_name/testsuites/rand_l_$length ; mkdir -p $archive_auts_dir/$aut_name/testsuites/rand_l_$length"
ret=$?
if [ $ret -ne 0 ]
then
   echo FAILED $ret
   exit 1
fi

#------------------------------
# Setup tools on staging host
#------------------------------

#
# Check out scripts
#
echo "*** TCGEN 1/11 Checking out tool scripts on stage machines ***"

# Delete $root_dir. Rest can remain.

action="rm -rf $root_dir  ; mkdir -p $dozen_dir ; svn co https://svn.cs.umd.edu/repos/guitar/dozen $dozen_dir"
do_action $username $stage_host "$action"
ret=$?
if [ $ret -ne 0 ]
then
   echo FAILED $ret
   exit $ret
fi

#
# Install tools 
#
echo "*** TCGEN 2/11 Building tool scripts on stage machines ***"

action="$dozen_dir/tools/scripts/main.sh $guitar_revision $checkout_type"
do_action $username $stage_host "$action"
ret=$?
if [ $ret -ne 0 ]
then
   echo FAILED $ret
   exit $ret
fi

#------------------------------
# Set up AUT on staging machine
#------------------------------

# Dozen directory already cleaned above

#
# Init dirs
#
echo "*** TCGEN 3/11 Initialising $aut_name directory structure ***"
action="$common_dir/common-init-dir.sh $aut_name"
do_action $username $stage_host "$action"
ret=$?
if [ $ret -ne 0 ]
then
   echo FAILED $ret
   exit $ret
fi

#
# Check out the AUT from Internet
#
echo "*** TCGEN 4/11 Check out the $aut_name on stage machine ***"
action="$common_dir/common-checkout.sh $aut_name"
do_action $username $stage_host "$action"
ret=$?
if [ $ret -ne 0 ]
then
   echo FAILED $ret
   exit $ret
fi

#
# Build AUT
#
echo "*** TCGEN 5/11 Building $aut_name on stage machine ***"
action="$common_dir/common-build.sh $aut_name"
do_action $username $stage_host "$action"
ret=$?
if [ $ret -ne 0 ]
then
   echo FAILED $ret
   exit $ret
fi

#
# Instrument aut 
#
echo "*** TCGEN 6/11 Instrumenting $aut_name on stage machine ***"
action="$common_dir/common-inst.sh $aut_name"
do_action $username $stage_host "$action"
ret=$?
if [ $ret -ne 0 ]
then
   echo FAILED $ret
   exit $ret
fi

#
# Rip AUT 
#
echo "*** TCGEN 7/11 Ripping $aut_name on stage machine ***"
rip_start=`date +%s`
action="$common_dir/common-rip.sh $aut_name /tmp/$tmpdirtag $x_lib_path $cmd_xvfb"
do_action $username $stage_host "$action"
ret=$?
if [ $ret -ne 0 ]
then
   echo FAILED $ret
   exit $ret
fi
rip_stop=`date +%s`

#
# Convert GUI to EFG
#
echo "*** TCGEN 8/11 Converting GUI to EFG on stage machine ***"
action="$common_dir/common-gui2efg.sh $aut_name $efg_arg_type"
do_action $username $stage_host "$action"
ret=$?
if [ $ret -ne 0 ]
then
   echo FAILED $ret
   exit $ret
fi

#
# Generate testcases
#
echo "*** TCGEN 9/11 Generating testcases on stage machine ***"
tcgen_start=`date +%s`
action="$common_dir/common-tc-gen-rand.sh $aut_name $length $numtc"
do_action $username $stage_host "$action"
ret=$?
if [ $ret -ne 0 ]
then
   echo FAILED $ret
   exit $ret
fi
tcgen_stop=`date +%s`

#
# Archive generated testcases to archive location
#
echo "*** TCGEN 10/11 Archiving testcases to archive machine ***"
action="$common_dir/util-rsync.sh $testsuites_dir/ $archive_username@$archive_hostname:$archive_auts_dir/$aut_name/testsuites/"
do_action $username $stage_host "$action"
ret=$?
if [ $ret -ne 0 ]
then
   echo FAILED $ret
   exit $ret
fi

#
# Archive generated models to archive location
#
echo "*** TCGEN 11/11 Archiving models to archive machine ***"
action="$common_dir/util-rsync.sh $aut_root_dir/models $archive_username@$archive_hostname:$archive_auts_dir/$aut_name/"
do_action $username $stage_host "$action"
ret=$?
if [ $ret -ne 0 ]
then
   echo FAILED $ret
   exit $ret
fi

#
#
# TODO: Delete staging directory
#

echo "*** Stats $aut_name ***"
echo Ripping time $((rip_stop - rip_start)) seconds
echo Testcase generation time $((tcgen_stop - tcgen_start)) seconds
echo "*** DONE Generating test cases ***"
exit $ret
