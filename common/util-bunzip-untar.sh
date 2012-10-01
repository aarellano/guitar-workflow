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

#--------------------------------------------------
# bunzip and utar all files in given directory.
#
#   By   baonn@cs.umd.edu
#   Date:    06/08/2011
#--------------------------------------------------

if [ $# -lt 1 ]
then
   echo "Usage: $0 <dir>"
   exit 1
fi

dir=$1

# Check local path
dir=$(readlink -f $dir)
if [ ! -e $dir ]
then
   echo FAILED Local directory does not exist.
   exit 1
fi


# For each .tar.bz2 file in $dir
ret=0
pushd $dir
for file in `ls *.tar.bz2`
do
   # Make directory, move file into it
   primary_name=${file%.tar.bz2}
   mkdir $primary_name
   mv $file $primary_name/

   # bunzip2, untar
   pushd $primary_name
   bunzip2 $primary_name.tar.bz2
   tar -xvf $primary_name.tar
   ret=$?
   popd

   # Check result
   if [ $ret -ne 0 ]
   then
      FAILED $file
      exit $ret
   fi

   # Delete .tar on success
   rm -f $primary_name/$primary_name.tar
   echo OK $file
done
popd

exit 0
