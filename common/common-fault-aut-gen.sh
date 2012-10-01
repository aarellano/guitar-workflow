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

echo "*** Generating mutant $2 $aut_name ***"

# Load aut local configuration 
source "$aut_scripts_dir/aut.cfg"
source "$aut_scripts_dir/aut.utils.sh"

# Read command line
fault_id=$2
if [ ! -e "$aut_fault_dir/$fault_id" ] || [ -z $fault_id ]
then
   echo "Usage: $0 <fault_id>"
   echo "Fault file $aut_fault_dir/$fault_id not found"
   exit 1
fi

cmd="patch -t -p0 < $aut_fault_dir/$fault_id"

pushd $aut_dir;
exec_cmd "$cmd"
ret=$?
popd

echo "*** DONE $aut_name ***"

exit $ret
