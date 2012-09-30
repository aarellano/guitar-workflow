#!/bin/bash 

echo "*** Initialising $aut_name directory ***"

#--------------------------------------
# Load parameters
#--------------------------------------
source "`dirname $0`/common-load-args.sh"

#--------------------------------------
# Load common layout
#--------------------------------------
source "`dirname $0`/common.cfg"
source "`dirname $0`/util.sh"

#--------------------------------------
# Load AUT layout
#--------------------------------------
source "$aut_scripts_dir/aut.cfg"

exec_cmd "mkdir -p $aut_root_dir"

exec_cmd "mkdir -p  $aut_dir"
exec_cmd "mkdir -p  $aut_src_dir"
exec_cmd "mkdir -p  $aut_bin_dir"
exec_cmd "mkdir -p  $aut_inst_dir"

exec_cmd "mkdir -p  $guitar_config_dir"
exec_cmd "mkdir -p  $model_dir"

exec_cmd "mkdir -p  $tmp_home"
exec_cmd "mkdir -p  $testsuite_root"

echo "*** DONE $aut_name ***"
