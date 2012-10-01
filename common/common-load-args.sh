#!/bin/bash
#  
#  Copyright (c) 2009-@year@. The GUITAR group at the University of Maryland. Names of owners of this group may
#  be obtained by sending an e-mail to atif@cs.umd.edu
# 
#  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated 
#  documentation files (the "Software"), to deal in the Software without restriction, including without 
#  limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
#  the Software, and to permit persons to whom the Software is furnished to do so, subject to the following 
#  conditions:
# 
#  The above copyright notice and this permission notice shall be included in all copies or substantial 
#  portions of the Software.
#
#  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT 
#  LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO 
#  EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER 
#  IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR 
#  THE USE OR OTHER DEALINGS IN THE SOFTWARE. 

####################################################
# Load and check aut arguments 
#
#	By	baonn@cs.umd.edu
#	Date: 	06/08/2011
####################################################

# load root dir for each aut
if [ $# -lt 1 ]
then
	echo "Usage: $0 <AUT name>"
	exit 1
fi 
export aut_name=$1

# if no root dir specified then we assume that 
# we are running from the common dir 
if [ -z $root_dir ]
then 
	export root_dir=`dirname $0`/..
fi 

echo "Root dir: $root_dir"
echo "AUT name: $aut_name"


