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

#############################
# Build Buddi to Buddi/bin/ dir
#	By	baonn@cs.umd.edu
#	Date: 	06/08/2011
##############################

#--------------
# Configuration
#--------------
source "$root_dir/common/common.cfg"
source "$root_dir/common/util.sh"
source "`dirname $0`/aut.cfg"

#--------------
# Parameter check
#--------------
echo "Build into $aut_bin_dir"
if [ ! -e $aut_bin_dir ]
then	
   exec_cmd "mkdir $aut_bin_dir"
   echo "DONE"
fi

#--------------
# Cleanup up old stuff
#--------------
exec_cmd "rm -rf $aut_bin_dir/* "
echo "DONE"

#--------------
# Build
#--------------
pushd $aut_src_dir
exec_cmd "sed -i 's/debug=\"off\"/debug=\"on\"/g' build.xml"
exec_cmd "ant"
popd
exec_cmd "cp -r $aut_src_dir/build/lib/*.jar $aut_bin_dir/"
exec_cmd "rm -rf $aut_src_dir/build/"
pushd $aut_bin_dir
exec_cmd "jar xf *.jar"
exec_cmd "rm -f *.jar"
popd

#--------------
# Sanity check
#--------------
ret=0
class=`echo $aut_mainclass | perl -pi -e 's/\./\//g' `
if [ ! -e $aut_bin_dir/$class.class ]
then
   echo FAILED build $aut_name
   ret=1
fi
exit $ret
