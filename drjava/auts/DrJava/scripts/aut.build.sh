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
# Build DrJava to DrJava/bin/ dir
#	By	baonn@cs.umd.edu
#	Date: 	06/08/2011
# 	Updated by aarella@umd.edu
#	Date:	30/09/2012
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
exec_cmd "export JAVA_HOME=/usr/lib/jvm/java-7-openjdk-i386"
exec_cmd "export JAVA7_HOME=/usr/lib/jvm/java-7-openjdk-i386"
exec_cmd "ant jar"
exec_cmd "cp drjava.jar $aut_bin_dir"
popd

exit 0
