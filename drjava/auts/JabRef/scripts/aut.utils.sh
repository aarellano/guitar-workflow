#!/bin/bash

#
# This script is used to clean up aut before each use.
# This also does AUT specific setup, such as preparing
# input files to the AUT.
#
function cleanup {
   if [ -z $tmp_home ]
   then
      echo FAILED tmp_home not specified
      exit 1
   fi

   # Delete coverage files
   exec_cmd "rm -f  $ripper_coverage_dir/*"
   exec_cmd "rm -rf $tmp_home"

   exec_cmd "mkdir -p $tmp_home"

   exec_cmd "cp $aut_input_dir/* $tmp_home/"

   return $?
}
