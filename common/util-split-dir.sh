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

####################################################
# Split a big test suite to smaller chunks. The
# original testcases are MOVED.
#
#   By   baonn@cs.umd.edu
#   Date:    06/08/2011
####################################################

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



if [ $# -lt 2 ]
then
   echo "Usage: $0 <testsuite-path> <number of partitions>" 
   exit 1
fi

#
# Should not source ANY file
#

# $aut_name is not used in this script
testcases_dir_name=testcases
testsuite=$(readlink -f $1)
split_number=$2

echo "*** Splitting testsuite $testsuite  ***"

original_testsuite_dir=$testsuite
splited_testsuite_dir_prefix=$testsuite

exec_cmd "pushd $original_testsuite_dir/$testcases_dir_name/"
if [ $? -ne 0 ]
then
   echo FAILED $original_testsuite_dir/$testcases_dir_name/
   exit 1
fi

total_test=`ls | grep tst | wc -l`
file_num_per_split=$(($total_test/$split_number))

echo Total test cases: $total_test
echo Number of test case per split: $file_num_per_split

moved=0
remainder=$(($total_test - $split_number * $file_num_per_split))
for ((i=0; i<$split_number; i++))
do
   target_testsuite_dir=$splited_testsuite_dir_prefix.$i
   if [ -e $target_testsuite_dir ]
   then
      rm -rf $target_testsuite_dir
   fi
   exec_cmd "mkdir -p $target_testsuite_dir"

   target_testcases_dir=$target_testsuite_dir/$testcases_dir_name
   exec_cmd "mkdir -p  $target_testcases_dir"

   echo Moving partition: $i

   # Distribute the "remainder"
   n=$file_num_per_split
   if [ $remainder -gt 0 ]
   then
      n=$(($file_num_per_split + 1))
      remainder=$(($remainder - 1))
   fi

   for test in `ls | grep tst | head -$((n))`
   do
      cmd="mv $test $target_testcases_dir"
      $cmd
      if [ $? -ne 0 ]
      then
         echo FAILED move command
         exit 1
      fi
   done

   m=`ls -l $target_testcases_dir/ | grep tst | wc -l`
   moved=$((moved+m))
   echo Moved: $m
done

echo Moved total: $moved
ret=0
if [ $moved -ne $total_test ]
then
   echo FAILED move operation
   ret=1
fi

# Exit the $original_testsuite_dir/$testcases_dir_name/
exec_cmd "popd"

exit $ret
