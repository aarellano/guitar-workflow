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
# Replay the test suites 
#
#   By   baonn@cs.umd.edu
#   Date:    06/08/2011
####################################################


echo "*** Replaying ***"

#--------------------------
# Parameter check
#--------------------------
if [ $# -lt 8 ]
then
   echo "Usage: $0 <AUT name> <gui-file> <efg-file> <testsuite-root-dir> <testsuite-name> <x-session-dir> <x-lib-path> <cmd-xvfb> [remote user] [remote host] [remote root]"
   exit 1
fi

#--------------------------
# Script configuration
#--------------------------
# Load common configuration
source "`dirname $0`/common-load-args.sh"
source "`dirname $0`/common.cfg"
source "`dirname $0`/util.sh"

# Load aut local configuration 
source "$aut_scripts_dir/aut.cfg"
source "$aut_scripts_dir/aut.utils.sh"

#--------------------------
# Virtual screen setup
#--------------------------
display_number=55
x_session_dir=$6
x_lib_path=$7
cmd_xvfb=$8

exec_cmd "cd /tmp/"
exec_cmd "rm -f nohup.out"
if [ $x_session_dir != "NULL" ]
then
   # First stop any previous Xvfb state
   stop_xvfb $display_number
   if [ $? -ne 0 ]
   then
      echo FAILED Unable to start Xvfb
      exit 1
   fi

   # Start new Xvfb
   start_xvfb $display_number $x_session_dir $x_lib_path $cmd_xvfb
   if [ $? -ne 0 ]
   then
      echo FAILED Unable to start Xvfb
      exit 1
   fi

   if [ -z $DISPLAY ]
   then
      export DISPLAY=:$display_number
   fi
fi 

#------------------------------
# Read input parameters
#------------------------------
aut_gui_file=$(readlink -f $2)
if [ ! -e "$aut_gui_file" ]
then
   echo FAILED Cannot find GUI file $2
   exit 1
fi

aut_efg_file=$(readlink -f $3)
if [ ! -e "$aut_efg_file" ]
then
   echo FAILED Cannot find EFG file $3
   exit 1
fi

testsuite_root=$(readlink -f $4)
testsuite=$5
testsuite=${testsuite%/}

remote_user=""
if [ ! -z $9 ]
then
   remote_user=$9
fi

remote_host=""
if [ ! -z ${10} ]
then
   remote_host=${10}
fi

remote_root_dir=""
if [ ! -z ${11} ]
then
   remote_root_dir=${11}
fi

if [ "$remote_user" != "" ] && [ "$remote_host" != "" ] && [ "$remote_root_dir" != "" ]
then
   remote="true"
fi


#------------------------------
# Other configuration
#------------------------------
function ssh_cmd_local {
   ssh_cmd $remote_user $remote_host "$1"

   return $?
}

ret=0
cmd_jfcripper=$guitar_dir/bin/jfcripper.sh
cmd_cobertura_report="$cobertura_dir/cobertura-mod-report-name.sh"
cmd_cobertura_merge="$cobertura_dir/cobertura-merge.sh"

if $colect_coverage
then 
   classpath=$cobertura_classpath:$aut_inst_classpath:$aut_classpath
else

   classpath=$aut_classpath
fi

# Output dirs
testsuite_dir=$testsuite_root/$testsuite
testsuite_testcases_dir=$testsuite_dir/$testcases_dir_name

# Environments
globalRet=0
tmp_aut_dir=$testsuite_dir

# Testsuite dirs
testsuite_oracles_dir=$tmp_aut_dir/$oracles_dir_name
testsuite_log_dir=$tmp_aut_dir/$log_dir_name
testsuite_coverage_dir=$tmp_aut_dir/$coverage_dir_name


#------------------------------
# Local directory setup
#------------------------------
# create tmp dirs
if [ ! -e $tmp_dir ]
then
   exec_cmd "mkdir $tmp_dir"
fi

if [ ! -e $tmp_aut_dir ]
then
   exec_cmd "mkdir $tmp_aut_dir"
fi

# Create output dirs
if [ ! -e $testsuite_dir ] 
then
   exec_cmd "mkdir $testsuite_dir"
fi

if [ ! -e $testsuite_oracles_dir ] 
then
   exec_cmd "mkdir $testsuite_oracles_dir"
fi

if [ ! -e $testsuite_log_dir ] 
then
   exec_cmd "mkdir $testsuite_log_dir"
fi

if [ ! -e $testsuite_coverage_dir ]; 
then
   exec_cmd "mkdir $testsuite_coverage_dir"
fi

#-----------------------------
# Remote directory setup
# If "remote" is enabled
#-----------------------------
if [ ! -z $remote ]
then
   #
   # Create root dir. DO NOT first delete the dir since
   # many machines are executing this script on the cluster.
   #
   remote_benchmark_root=$remote_root_dir/$aut_name
   ssh_cmd_local "mkdir -p $remote_benchmark_root"

   # Create AUT dirs
   remote_root_aut=$remote_benchmark_root/aut
   remote_model_dir=$remote_benchmark_root/models

   ssh_cmd_local "mkdir -p $remote_root_aut"
   ssh_cmd_local "mkdir -p $remote_model_dir"

   # Create testsuites dir 
   remote_root_testsuite=$remote_benchmark_root/testsuites/${testsuite%.*}
   remote_test_dir=$remote_root_testsuite/$testcases_dir_name
   remote_log_dir=$remote_root_testsuite/$log_dir_name
   remote_oracle_dir=$remote_root_testsuite/$oracles_dir_name
   remote_coverage_dir=$remote_root_testsuite/$coverage_dir_name
   remote_coverage_steps_dir=$remote_root_testsuite/$coverage_dir_name/steps

   ssh_cmd_local "mkdir -p $remote_root_testsuite"
   ssh_cmd_local "mkdir -p $remote_test_dir"
   ssh_cmd_local "mkdir -p $remote_log_dir"
   ssh_cmd_local "mkdir -p $remote_oracle_dir"
   ssh_cmd_local "mkdir -p $remote_coverage_dir"
   ssh_cmd_local "mkdir -p $remote_coverage_steps_dir"

   #-----------------------------
   # Sync EFG and GUI file
   #--------------------------
   exec_cmd "rsync  -axvu --progress --stats  --exclude 'archive*' $aut_efg_file $remote_user@$remote_host:$remote_model_dir"

   exec_cmd "rsync  -avu --progress --stats  --exclude 'archive*' $aut_gui_file $remote_user@$remote_host:$remote_model_dir"
fi

#--------------------------
# Cobertura files
#--------------------------
cobertura_main_file=$tmp_aut_dir/cobertura_$aut_name.ser
cobertura_testsuite_clean=$tmp_aut_dir/cobertura_clean_$aut_name.ser
cobertura_output_dir=$testsuite_coverage_dir
local_cobertura_testsuite_file=$testsuite_coverage_dir/$testsuite.ser
local_html_coverage_report_dir=$testsuite_coverage_dir/$coverage_html_dir_name

exec_cmd "cp -f $cobertura_data_file_clean  $cobertura_main_file"
exec_cmd "cp -f $cobertura_data_file_clean  $cobertura_testsuite_clean"
exec_cmd "cp -f $cobertura_data_file_clean  $local_cobertura_testsuite_file"

#--------------------------
# Replay
#--------------------------

# Setup java command line parameters
export JAVA_CMD_PREFIX="java -Xms64m -Xmx512m -Duser.home=$tmp_home -Dnet.sourceforge.cobertura.datafile=$cobertura_main_file "

for testcase in `find $testsuite_testcases_dir -name "*.tst"`
do
   testname=`basename "$testcase"`
   testname=${testname%.*}

   echo "*** Executing $testname ***" 

   echo Cleaning up $aut_name
   cleanup
   sleep 1

   local_test_file=$testsuite_testcases_dir/$testname.tst
   local_log_file=$testsuite_log_dir/$testname.log
   local_LOG_file=$testsuite_log_dir/$testname.LOG
   local_oracle_file=$testsuite_oracles_dir/$testname.orc 

   cmd="$cmd_jfcreplayer  -cp  $classpath  $replayer_launcher -c $aut_mainclass -g $aut_gui_file -e  $aut_efg_file -t $local_test_file -l $local_LOG_file -gs $local_oracle_file  -i $aut_initial_waitting_time -d $aut_replay_delay -cf $aut_configuration_file -to $aut_replay_timeout -d $aut_replay_delay -so $aut_replay_step_timeout"

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

   #----------------------
   # Cobertura-plugin arguments 
   #----------------------
   local_cobertura_output_dir=$testsuite_coverage_dir/$testname
   if [ ! -d $local_cobertura_output_dir ]       
   then
      exec_cmd "mkdir $local_cobertura_output_dir"
   fi
   local_cobertura_output_ser_dir=$local_cobertura_output_dir/$coverage_ser_dir_name   

   if $colect_coverage; then
      cmd="$cmd -cc $cobertura_testsuite_clean -cd $local_cobertura_output_ser_dir "
   fi 

   if [ ! -z $ext_timeout ]
   then
      cmd="timeout.sh $((aut_replay_timeout/1000 +2)) $cmd"
   fi

   #----------------------
   # Execute replay
   #----------------------
   replay_start=`date +%s`
   pushd $tmp_home
   exec_cmd "$cmd 2>&1 | tee $local_log_file"
   ret=$?
   popd
   replay_stop=`date +%s`
   if [ $ret -ne 0 ]
   then
      echo FAILED replaying on `hostname` $testname
      echo FAILED replaying $cmd
      echo FAILED continuing with next
      globalRet=$ret
   fi
   exec_cmd "sync"

   #----------------------
   # Process coverage files
   #----------------------
   sleep 1
   cov_proc_start=`date +%s`
   if [ $colect_coverage ] && [ $ret -eq 0 ]
   then

      # coverage files
      # merge all steps coverage
      $cmd_cobertura_merge --datafile $local_cobertura_output_ser_dir/$testname.ser $local_cobertura_output_ser_dir/*.ser

      # merge to general test suite coverage
      $cmd_cobertura_merge --datafile $local_cobertura_testsuite_file $local_cobertura_output_ser_dir/$testname.ser

      sleep 1
      # convert to xml files
      find $local_cobertura_output_dir -name "*.ser" -exec $cmd_cobertura_report {} \; 
      $cmd_cobertura_report    $local_cobertura_testsuite_file
      
      # compress coverage files
      archive_type=tar.bz2
      local_cobertura_archive=$testsuite_coverage_dir/$testname.$archive_type

      pushd $local_cobertura_output_ser_dir
      cmd="tar cjvf  $local_cobertura_archive *.xml"
      exec_cmd "$cmd"
      popd

   fi   # end check collecting coverage 
   cov_proc_stop=`date +%s`

   #----------------------
   # Copy files to remote site
   #----------------------
   rsync_start=`date +%s`
   if [ ! -z $remote ] && [ $ret -eq 0 ]
   then 
      # Testcase file
      remote_test_file=$remote_test_dir/$testname.tst
      exec_cmd "rsync -q -avz $local_test_file $remote_user@$remote_host:$remote_test_file"
      ret1=$?

      # Log file 
      remote_log_file=$remote_log_dir/$testname.log
      exec_cmd "rsync -q -avz $local_log_file $remote_user@$remote_host:$remote_log_file"
      ret2=$?
      exec_cmd "rm -f $local_log_file"

      # LOG file 
      remote_LOG_file=$remote_log_dir/$testname.LOG
      def_log_file=$tmp_home/GUITAR-Default.log
      if [ -e $local_LOG_file ]
      then
         exec_cmd "rsync -q -avz $local_LOG_file $remote_user@$remote_host:$remote_LOG_file"
         exec_cmd "rm -f $local_LOG_file"

      elif [ -e "$def_log_file" ]
      # Default LOG file 
      then
         exec_cmd "rsync -q -avz $def_log_file $remote_user@$remote_host:$remote_LOG_file"
         exec_cmd "rm -f $def_log_file"
      fi

      # Oracle file 
      remote_oracle_file=$remote_oracle_dir/$testname.orc
      exec_cmd "rsync -q -avz $local_oracle_file $remote_user@$remote_host:$remote_oracle_file"
      ret3=$?
      exec_cmd "rm -f $local_oracle_file"

      #
      # Copy test case coverage files
      # TODO: Using rsync to sync entire dir
      #

      # Remote_coverage_dir=$remote_coverage_dir
      exec_cmd "rsync -q -avz $local_cobertura_archive  $remote_user@$remote_host:$remote_coverage_steps_dir"
      ret4=$?
      exec_cmd "rm -rf $local_cobertura_archive"
      exec_cmd "rm -rf $local_cobertura_output_dir"

      # Copy test suite coverage file
      exec_cmd "rsync -q -avz $local_cobertura_testsuite_file $remote_user@$remote_host:$remote_coverage_dir"
      ret5=$?

      exec_cmd "rsync -q -avz  ${local_cobertura_testsuite_file%ser}xml $remote_user@$remote_host:$remote_coverage_dir"
      ret6=$?

      # Handle transfer failure.
      if [ $ret1 -ne 0 ] || [ $ret2 -ne 0 ] || [ $ret3 -ne 0 ] || [ $ret4 -ne 0 ] || [ $ret5 -ne 0 ] || [ $ret6 -ne 0 ]
      then
         echo FAILED rsync or scp $local_test_file
      fi

   fi   # Copy results to archive location
   rsync_stop=`date +%s`

   # --------------------
   # Cleaning up 
   # --------------------
   exec_cmd "rm -rf $local_cobertura_output_dir"
   exec_cmd "killall firefox-bin"

   # --------------------
   # Log time
   # --------------------
   echo Replay time $((replay_stop - replay_start))
   echo Cobertura process time $((cov_proc_stop - cov_proc_start))
   echo Rsync time $((rsync_stop - rsync_start))
done  # for each testcase

#-----------------------------
# Clean up
#-----------------------------
if [ $x_session_dir != "NULL" ]
then 
   stop_xvfb 55
   env --unset=DISPLAY > /dev/null
fi

if [ -e nohup.out ]
then
   exec_cmd "rsync -avz nohup.out $remote_user@$remote_host:/$remote_test_dir/nohup-$testsuite"
   exec_cmd "rm -f nohup.out"
fi
exec_cmd "rm -f *.log"
exec_cmd "rm -rf ~/NewFolder*"

if [ $globalRet -ne 0 ]
then
   echo FAILED replay
fi
echo "*** DONE $aut_name ***"

#
# Might consider not returning an error code
# if an individual replay fails. Instead return
# a non-zero status only if there is a global 
# error.
exit $globalRet
