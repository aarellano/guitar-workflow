#!/bin/bash
#
# $workspace = location of jenkins SVN tree
# $JAVA_HOME = JDK location (required by some AUTs)
#

java=$1
workspace=$2
x_session_dir=$3
aut_name=$4
seq_len=$5
tc_count=$6

if [ -z $java ] ||  [ -z $workspace ] || [ -z $aut_name ] || [ -z $seq_len ] || [ -z $tc_count ]
then
    echo "Usage: $0 <java-home> <workspace-root> <aut-name> <sequence-length> <num-testcases>"
    exit 1
fi

if [ -z $workspace ]
then
    workspace=`pwd`
fi

echo "Workspace is $workspace"

export PATH=$PATH:$workspace/dozen/common/
export PATH=$PATH:$workspace/dozen/tools/scripts/
export PATH=$PATH:$workspace/dozen/tools/cobertura/
export PATH=$PATH:$workspace/dozen/tools/bin/guitar/bin/

export aut_root=$workspace/dozen/auts/


if [ -z $JAVA_HOME ]
then
    echo "Please set $JAVA_HOME"
fi

echo "Java is at $JAVA_HOME"

# Prepare GUITAR tools
echo "*** Building GUITAR tools ***"
main.sh HEAD num
ret=$?
if [ $ret -ne 0 ]
then
   exit $ret
fi

# Test the aut
common-init-dir.sh $aut_name
ret=$?
if [ $ret -ne 0 ]
then
   exit $ret
fi

common-checkout.sh $aut_name
ret=$?
if [ $ret -ne 0 ]
then
   exit $ret
fi

common-build.sh $aut_name
ret=$?
if [ $ret -ne 0 ]
then
   exit $ret
fi

common-inst.sh $aut_name
ret=$?
if [ $ret -ne 0 ]
then
   exit $ret
fi

common-build-check.sh $aut_name
ret=$?
if [ $ret -ne 0 ]
then
   exit $ret
fi

common-rip.sh $aut_name $x_session_dir $x_lib_path $cmd_xvfb
ret=$?
if [ $ret -ne 0 ]
then
   exit $ret
fi

common-gui2efg.sh $aut_name new
ret=$?
if [ $ret -ne 0 ]
then
   exit $ret
fi

common-efg2gephipdf.sh $aut_name
ret=$?
if [ $ret -ne 0 ]
then
   exit $ret
fi

common-tc-gen-sq.sh $aut_name $seq_len $tc_count
ret=$?
if [ $ret -ne 0 ]
then
   exit $ret
fi

common-replay.sh $aut_name $aut_root/$aut_name/models/$aut_name.GUI $aut_root/$aut_name/models/$aut_name.EFG $aut_root/$aut_name/testsuites/ sq_l_2 $x_session_dir $x_lib_path $cmd_xvfb
ret=$?
if [ $ret -ne 0 ]
then
    exit $ret
fi

# Ignore tar-ing and comparing errors
exit 0
