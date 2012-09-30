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
# Rip the application
#
#	By	baonn@cs.umd.edu
#	Date: 	06/08/2011
####################################################

#--------------------------
# Script configuration
#--------------------------
# Load common configuration
source "`dirname $0`/common-load-args.sh"
source "`dirname $0`/common.cfg"
source "`dirname $0`/util.sh"

echo "*** Launching $aut_name ***"

# Load aut local configuration 
source "$aut_scripts_dir/aut.cfg"
source "$aut_scripts_dir/aut.utils.sh"

# Prepare output directory 
exec_cmd "mkdir -p $model_dir"
exec_cmd "mkdir -p $tmp_home"

classpath=$aut_classpath
cmd="java -Duser.home=$tmp_home -cp $classpath $aut_mainclass"

if [ ! -z $aut_arguments ] 
then
   aut_arguments=`echo $aut_arguments | perl -pi -e 's/:/ /g' `
   cmd="$cmd $aut_arguments"	
fi

if [ ! -z $aut_arguments2 ] 
then
   aut_arguments2=`echo $aut_arguments2 | perl -pi -e 's/:/ /g' `
   cmd="$cmd $aut_arguments2"
fi

echo Cleaning up $aut_name
cleanup
	
#--------------------------
# Launching AUT
#--------------------------
echo "Sleeping for 1s"
sleep 1

pushd $tmp_home
echo $cmd
$cmd 2>&1
ret=$?
popd

echo "*** DONE Launching $aut_name ***"
exit $ret
