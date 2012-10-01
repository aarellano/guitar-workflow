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
# Convert .GUI file to .EFG file
#
#	By	baonn@cs.umd.edu
#	Date: 	06/08/2011
####################################################


source "`dirname $0`/common-load-args.sh"
source "`dirname $0`/common.cfg"
source "`dirname $0`/util.sh"

echo "*** Generating $aut_name patch files ***"

# Load aut local configuration 
source "$aut_scripts_dir/aut.cfg"
source "$aut_scripts_dir/aut.utils.sh"

if [ ! -e $aut_src_dir ]
then
   echo $aut_src_dir does not exist.
   exit 1
fi

if [ ! -e $aut_src_fault_dir ]
then
   echo $aut_src_fault_dir does not exist.
   exit 1
fi

cmd="perl $root_dir/common/common-fault-patch-gen.pl $aut_src_dir $aut_src_fault_dir"

pushd $aut_dir;
exec_cmd "$cmd"
ret=$?

if [ $ret -eq 0 ]
then
   exec_cmd "rm -rf $aut_fault_dir ; mv fault $aut_fault_dir"
fi
popd

echo "*** DONE $aut_name ***"

exit $ret
