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
# Instrument the  application
#
#	By	baonn@cs.umd.edu
#	Date: 	06/08/2011
####################################################

#--------------------------------------
# Load parameters
#--------------------------------------
source "`dirname $0`/common-load-args.sh"
echo "*** Instrumenting $aut_name ***"

if [ -z $aut_name ] || [ -z $root_dir ]
then
   echo "FAILED aut_name root_dir not specified"
   exit 1
fi

#--------------------------------------
# Load common layout
#--------------------------------------
source "`dirname $0`/util.sh"
source "`dirname $0`/common.cfg"

#--------------------------------------
# Load aut local configuration
#--------------------------------------
source "$aut_scripts_dir/aut.cfg"

# Creating dirs
exec_cmd "mkdir -p $aut_inst_dir"

# Instrument
pushd $aut_bin_dir
cmd="cobertura-instrument --destination $aut_inst_dir --datafile $cobertura_data_file_clean $aut_cov_bin_list"
exec_cmd "$cmd"
popd
ret=$?

echo "*** DONE $aut_name ***"
exit $ret
