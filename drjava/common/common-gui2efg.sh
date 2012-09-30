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
echo "*** Generating EFG $aut_name ***"

# Load aut local configuration 
source "$aut_scripts_dir/aut.cfg"
source "$aut_scripts_dir/aut.utils.sh"

# Remove 0x0c character from .GUI file for some AUTs
exec_cmd "sed -i 's/\d12//' $aut_gui_file"

# Check additional argument
efg_arg_type=$2
if [ -z $efg_arg_type ]
then
    echo "efg_arg_type not specified"
    exit 1
fi

# Run converter
cmd_gui2efg=$guitar_dir/dist/guitar/gui2efg.sh

if [ $efg_arg_type = "old" ]
then
   cmd="$cmd_gui2efg $aut_gui_file $aut_efg_file"
elif [ $efg_arg_type = "new" ]
then
   cmd="$cmd_gui2efg -g $aut_gui_file -e $aut_efg_file"
else
   echo "Unknown efg_arg_type $efg_arg_type. Should be 'old' or 'new'."
   exit 1
fi

exec_cmd "$cmd"
ret=$?

exec_cmd "rm -f *.log"

echo "*** DONE $aut_name ***"

exit $ret
