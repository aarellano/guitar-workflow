#!/bin/bash

#
# This script contain utility functions common used across scripts  
#

#
#
#
function start_xvfb {
   # $1 = display_number
   # $2 = session_dir
   # $3 = lib_path
   # $4 = cmd_xvfb

   display_number=$1
   if [ -z $display_number ]
   then
      echo FAILED display_number not set
      exit 1
   fi

   session_dir=$2
   if [ ! -e $session_dir ]
   then   
      mkdir -p $session_dir
      if [ $? -ne 0 ]
      then
         echo FAILED could not create $session_dir
         exit 1
      fi
   fi 

   lib_path=$3
   cmd_xvfb=$4

   echo display_number is $display_number
   echo session_dir is $session_dir
   echo lib path is $lib_path
   echo xvfb command is $cmd_xvfb

   `dirname $0`/util-xvfb.sh start $display_number $session_dir $lib_path $cmd_xvfb
   ret=$?

   return $ret
}

#
#
#
function stop_xvfb() {
   display_number=$1
   `dirname $0`/util-xvfb.sh stop $display_number

   return $?
}

#
# pause for a while 
#
function pause {
   read -p  "Press ENTER to continue..."
}

#
# Execute a command while printing
# the command itself.
#
function exec_cmd
{
   echo $*
   eval $*

   return $?
}

#
# Execute a command without printing
# the command itself.
#
function exec_cmd_q
{
   eval $*

   return $?
}

#
#
# Execute a remote command. Print the
# command itself.
#
# $1 = remote username
# $2 = remote machine name in the format host:port OR host
# $3 = remote command
# $4 = postfix, such as "&"
#
function ssh_cmd {
   remote_user=$1
   remote_cmd=$3

   remote_host_name=$(echo "$2" | awk -F ":" '{print $1}')
   remote_port=$(echo "$2" | awk -F ":" '{print $2}')

   postfix=$4

   if [ -z "$remote_port" ]
   then
      exec_cmd "ssh -o ConnectTimeout=30 -o StrictHostKeyChecking=no $remote_user@$remote_host_name '$remote_cmd 2>&1' $postfix"
   else
      exec_cmd "ssh -o ConnectTimeout=30 -o StrictHostKeyChecking=no -p $remote_port $remote_user@$remote_host_name '$remote_cmd 2>&1' $postfix"
   fi

   return $?
}

#
#
# Execute a remote command without 
# printing the command itself.
#
# $1 = remote username
# $2 = remote machine name in the format host:port OR host
# $3 = remote command
# $4 = postfix such as "&"
#
function ssh_cmd_q {
   remote_user=$1
   remote_cmd=$3

   remote_host_name=$(echo "$2" | awk -F ":" '{print $1}')
   remote_port=$(echo "$2" | awk -F ":" '{print $2}')

   postfix=$4

   if [ -z "$remote_port" ]
   then
      exec_cmd_q "ssh -o ConnectTimeout=30 -o StrictHostKeyChecking=no $remote_user@$remote_host_name '$remote_cmd 2>&1' $postfix"
   else
      exec_cmd_q "ssh -o ConnectTimeout=30 -o StrictHostKeyChecking=no -p $remote_port $remote_user@$remote_host_name '$remote_cmd 2>&1' $postfix"
   fi

   return $?
}

#
# Execute rsync:
#
# $1 = local file(s)
# $2 = remote username
# $3 = remote machine name in the format host:port OR host
# $4 = remote path
#
function rsync_cmd_a {
   local_path=$1
   remote_user=$2

   remote_host_name=$(echo "$3" | awk -F ":" '{print $1}')
   remote_port=$(echo "$3" | awk -F ":" '{print $2}')

   remote_path=$4

   if [ -z "$remote_port" ]
   then
      exec_cmd "rsync -e \"ssh -o ConnectTimeout=30 -o StrictHostKeyChecking=no \" -avzq $local_path $remote_user@$remote_host_name:$remote_path 2>&1"
   else
      exec_cmd "rsync -e \"ssh -o ConnectTimeout=30 -o StrictHostKeyChecking=no -p $remote_port \" -avzq $local_path $remote_user@$remote_host_name:$remote_path 2>&1"
   fi

   return $?
}

#
# Execute rsync:
#
# $1 = remote username
# $2 = remote machine name in the format host:port OR host
# $3 = remote path
# $4 = local file(s)
#
function rsync_cmd_b {
   remote_user=$1

   remote_host_name=$(echo "$2" | awk -F ":" '{print $1}')
   remote_port=$(echo "$2" | awk -F ":" '{print $2}')

   remote_path=$3
   local_path=$4

   if [ -z "$remote_port" ]
   then
      exec_cmd "rsync -e \"ssh -o ConnectTimeout=30 -o StrictHostKeyChecking=no \"  -avzq $remote_user@$remote_host_name:$remote_path $local_path 2>&1"
   else
      exec_cmd "rsync -e \"ssh -o ConnectTimeout=30 -o StrictHostKeyChecking=no -p $remote_port \" -avzq $remote_user@$remote_host_name:$remote_path $local_path 2>&1"
   fi

   return $?
}
