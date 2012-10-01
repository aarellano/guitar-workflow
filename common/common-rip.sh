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
echo "*** Ripping $aut_name ***"

#--------------------------
# Command line arguments
#--------------------------
# $1 = $aut_name
# $2 = tmp_dir        (NULL = no Xvfb)
# $3 = lib_path       (NULL = no Xvfb)
# $4 = cmd_xvfb       (NULL = no Xvfb)

if [ -z $2 ] || [ -z $3 ] || [ -z $4 ]
then
   echo "Usage: $0 <AUT name> <x session dir> <x lib path> <cmd xvfb>"
   exit 1
fi

# Load aut local configuration 
source "$aut_scripts_dir/aut.cfg"
source "$aut_scripts_dir/aut.utils.sh"

#--------------------------
# Virtual screen setup 
#--------------------------
# start virtual screen buffer

if [ $2 != "NULL" ]
then
   stop_xvfb 55
   if [ $? -ne 0 ]
   then
      echo FAILED Unable to stop previous Xbfv if any
      exit 1
   fi
   env --unset=DISPLAY > /dev/null
   start_xvfb 55 $2 $3 $4
   if [ $? -ne 0 ]
   then
      echo FAILED Unable to start Xvfb
      exit 1
   fi

   if [ -z $DISPLAY ]
   then
      export DISPLAY=:55
   fi
fi

#--------------------------
# Ripping setup
#--------------------------
classpath=$cobertura_classpath:$aut_inst_classpath:$aut_classpath
cobertura_ripping_file="$ripper_coverage_dir/cobertura_ripper.ser"

# Prepare output directory 
exec_cmd "mkdir -p $aut_root_dir/home/"
exec_cmd "mkdir -p $model_dir"
exec_cmd "mkdir -p $tmp_home"
exec_cmd "mkdir -p $ripper_coverage_dir"

# Setup java command line parameters
export JAVA_CMD_PREFIX="java -Duser.home=$tmp_home -Xms64m -Xmx768m  -Dnet.sourceforge.cobertura.datafile=$cobertura_ripping_file -Dlog4j.configuration=log/guitar-clean.glc" 

cmd="$cmd_jfcripper -cp $classpath $ripper_launcher -c $aut_mainclass -g $aut_gui_file -i $aut_initial_waitting_time  -cf $aut_configuration_file -d $aut_ripper_delay -m"

if [ ! -z $aut_arguments ] 		
then
   cmd="$cmd -a $aut_arguments"	
fi

if [ ! -z $aut_arguments2 ]
then
   cmd="$cmd:$aut_arguments2"
fi

if $reg_title_match; then
   cmd="$cmd -r"
fi

echo Cleaning up $aut_name
cleanup
if [ ! -z $aut_model_data_dir ] && [ -e $aut_model_data_dir ]
then
   exec_cmd "rm -rf $aut_model_data_dir"
fi

#--------------------------
# Instrumentation setup 
#--------------------------
exec_cmd "cp -f $cobertura_data_file_clean $cobertura_ripping_file"

#--------------------------
# Ripping
#--------------------------
echo "Sleeping for 1s"
sleep 1

pushd $tmp_home
$cmd 2>&1 | tee $ripper_log_file
ret=$?
popd

#--------------------------
# Virtual screen cleanup
#--------------------------
# stop virtual screen buffer
if [ $2 != "NULL" ]
then
   stop_xvfb 55
   if [ $? -ne 0 ]
   then
      echo FAILED Unable to stop previous Xbfv if any
      exit 1
   fi
   env --unset=DISPLAY > /dev/null
fi


#--------------------------
# Cobertura post-process
#--------------------------
exec_cmd "$cmd_cobertura_report $cobertura_ripping_file"

#--------------------------
# Cleanup
#--------------------------
if [ -e nohup.out ]
then
   exec_cmd "rm -f nohup.out"
fi
if [ -e *.log ]
then
   exec_cmd "rm -f *.log"
fi
if [ -e log_widget.xml ]
then
   exec_cmd "rm -f log_widget.xml"	
fi
exec_cmd "killall -9 firefox-bin"
exec_cmd "rm -rf $tmp_home"

echo "*** DONE $aut_name ***"
exit $ret
