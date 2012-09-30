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

#
# This is a script to generate the slice for each
# event in a testcase. Thi script read the cobertura
# coverage report for an event, determines the method
# invoked in that event and runs the JavaSlicer to
# compute the slice for that event.
#
# Slices are generated for each testcase in the
# specified testsuite.
#

#
#--------------------------
# Script configuration
#--------------------------
# Load common configuration
source "`dirname $0`/common-load-args.sh"
source "`dirname $0`/common.cfg"
source "`dirname $0`/util.sh"

echo "*** Slicing $aut_name ***"

#--------------------------
# Command line arguments
#--------------------------
# $1 = $aut_name
# $2 = testsuite root dir
# $3 = testsuite name

if [ -z $2 ] || [ -z $3 ]
then
   echo "Usage: $0 <AUT name> <testsuite-root-dir> <testsuite-name>"
   exit 1
fi

# Load aut local configuration 
source "$aut_scripts_dir/aut.cfg"
source "$aut_scripts_dir/aut.utils.sh"

# Setup java command line parameters

# Need to append -t <thread_id> <trace_file> <slice_condition>"
cmd="java -Xmx6g -jar slicer.jar -p "

#--------------------------
# Directory variables
#--------------------------

testsuite_root=$(readlink -f $2)
testsuite=$3
testsuite=${testsuite%/}

testsuite_dir=$testsuite_root/$testsuite
coverage_dir=$testsuite_dir/$coverage_dir_name/steps
slice_dir=$testsuite_dir/$slice_dir_name
tmp_cov_summary=/tmp/cov
trace_ext=trace


#--------------------------
# Parameter check
#--------------------------

if [ ! -e $slice_dir ]
then
   echo Slice directory $slice_dir not found
   exit 1
fi

if [ ! -e "$coverage_dir" ]
then
   echo Coverage dir $coverage_dir not found
   exit 1
fi

#--------------------------
# Slice
#--------------------------

for tc in `ls $coverage_dir`
do
   for cov_txt in `find $coverage_dir/$tc/ -name "*.txt"`
   do
      cov_txt_base=`basename $cov_txt`

      #
      # Ignores "<init>" in the XML coverage files. These
      # correspond to class constructors. Ignored "default"
      # these appear to be duplicate entries in the XML.
      #
      exec_cmd "cat $cov_txt | awk '{print \$2\".\"\$3}' | sort -u | grep -v default | grep -v init > $tmp_cov_summary"

      #
      # Find slice for each method in coverage
      #
      coverage_file=`basename "$cov_txt"`
      trace_file="$slice_dir/$tc.$trace_ext"

      if [ ! -e $trace_file ]
      then
         echo Trace file $trace_file not found for $cov_txt
         exit 1;
      fi

      if [ ! -e "$slice_dir/$tc" ]
      then
         exec_cmd "mkdir -p $slice_dir/$tc"
      fi

      for method in `cat $tmp_cov_summary`
      do
         # Replace $ with -
         patched_method=`echo $method | sed s/\\\\$/-/g`

         slice_cmd="$cmd $trace_file '$method' > \"$slice_dir/$tc/$cov_txt_base.$patched_method.slice\" "
         exec_cmd "$slice_cmd"

      done   # for all methods

      # Combine all per-method slices into one file
      exec_cmd "cat $slice_dir/$tc/*.slice > $slice_dir/$tc.slice"

   done   # for all coverage files

done   # for all testcases
