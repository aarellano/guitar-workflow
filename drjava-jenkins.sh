#!/bin/bash
# This script rips and runs test cases on DrJava using GUITAR

usage()
{
	echo "
	USAGE
	$0 [options]

	DESCRIPTION
	This script enables and runs a simple example workflow on using GUITAR

	OPTIONS
		-h	shows this message
		-x	by default this script uses xvfb to perform all graphical operations in memory.
			If -x is specified, then the graphics will be shown on a standard X11 server
		-c	Maximum number of test cases to write and replay. If 0 all the test cases are run.
			By default is only 2
		-m	if this flag is set, then the software will run manually (no automated test cases).
		-r	skip ripping the application.
		-n	setting this flag, no tests will be run.
		"
}

xvfb=true
max_num_testcases=2
auto_run=true
skip_ripping=false
run_tests=true
while getopts ":h :x :m :c: :r :n" opt; do
  case $opt in
	h)
		usage
		exit 0
		;;
	x)
		XVFB=false
		;;
	c)
		max_num_testcases=$OPTARG
		;;
	m)
		auto_run=false
		;;
	r)
		skip_ripping=true
		;;
	n)
		run_tests=false
		;;
	\?)
      echo "Invalid option: -$OPTARG" >&2
      	exit 1
		;;
  esac
done

if [ -z $WORKSPACE ]
	then workspace='/var/lib/jenkins/workspace/phase2'
	else workspace=$WORKSPACE
fi
scripts=$workspace'/guitar-scripts'
aut_path=$workspace'/drjava'
aut_cp=$aut_path/'drjava.jar'
cobertura_CP=$workspace'/cobertura/cobertura1.9.4.1/cobertura.jar'
reports_path=$workspace'/cobertura-reports'
aut_build_file=$aut_path/'build.xml'
aut_bin=$workspace'/aut_bin'
aut_inst=$workspace'/aut_inst'
guitar_path=$workspace'/guitar'
guitar_build_file=$guitar_path'/build.xml'
guitar_dist_base_dir=$guitar_path'/dist/guitar'
guitar_lib=$guitar_dist_base_dir/jars
mainclass='edu.rice.cs.drjava.DrJava'
configuration="$workspace/guitar-config/configuration.xml"
intial_wait=2000
# delay time between two events during ripping
ripper_delay=500
# the length of test suite
tc_length=2
# the maximum number of test case generated (0 means generate all)
tc_no=$max_num_testcases
# delay time between two events during replaying
# this number is generally smaller than the $ripper_delay
relayer_delay=200
# Directory to store all output of the workflow
output_dir=$workspace'/output'
# GUI structure file
gui_file="$output_dir/DrJava.GUI"
# EFG file
efg_file="$output_dir/DrJava.EFG"
# Log file for the ripper
# You can examine this file to get the widget
# signature to ignore during ripping
log_file="$output_dir/DrJava.log"
# Test case directory
testcases_dir="$output_dir/testcases"
# GUI states directory
states_dir="$output_dir/states"
# Replaying log directory
logs_dir="$output_dir/logs"

# Preparing output directories
mkdir -p $output_dir
mkdir -p $testcases_dir
mkdir -p $states_dir
mkdir -p $logs_dir
mkdir -p $reports_path

echo 'Checking for administrative privileges'
if ! groups | grep 'root\|admin\|sudo\|cluster' > /dev/null ; then
	echo 'You need to run this script as root, or better yet, using passwordless sudo'
	exit 1
else
	echo 'OK'
fi
echo
## END CHECKING FOR ADMINISTRATIVE PRIVILEGES

echo 'Checking for required software'
if ! java -version 2>&1 | grep 1.7 > /dev/null ; then
	packages+=' openjdk-7-jdk' > /dev/null
	if which java ; then
		sudo apt-get -x remove openjdk-6-jdk openjdk-6-jre openjdk-6-jre-lib
		sudo apt-get -y autoremove
	fi
fi

if ! which ant ; then packages+=' ant'; fi > /dev/null
if ! which svn ; then packages+=' subversion'; fi > /dev/null
if ! which xvfb-run ; then packages+=' xvfb'; fi > /dev/null
if perl -e 'use XML::Simple;' 2>&1 | grep -q "Can't locate XML"; then packages+=' libxml-simple-perl'; fi
if ! which cobertura-instrument ; then packages+=' cobertura'; fi > /dev/null
if [ -n "$packages" ]; then
	echo 'Updating repositories and packages...'
	sudo apt-get update > /dev/null && sudo apt-get -y upgrade > /dev/null
	echo "Installing new packages: $packages"
	sudo apt-get -y install $packages
fi
echo
## END CHECKING FOR REQUIRED SOFTWARE

if [ ! -d $workspace/cobertura ]; then
	echo 'Updating cobertura.jar'
	mkdir -p $workspace/cobertura
	wget http://sourceforge.net/projects/cobertura/files/cobertura/1.9.4.1/cobertura-1.9.4.1-bin.tar.gz
	tar -C $workspace/cobertura -xzf cobertura-1.9.4.1-bin.tar.gz
	rm -f cobertura-1.9.4.1-bin.tar.gz
	rm -f $JFC_DIST_PATH/jars/cobertura.jar
fi

if [ ! -d $guitar_path ]; then
	echo 'Checking out GUITAR source'
	mkdir -p $guitar_path
	svn co https://guitar.svn.sourceforge.net/svnroot/guitar/trunk@3320 $guitar_path
fi

if [ ! -d $guitar_path/dist ]; then
	echo 'Building the GUITAR target jfc.dist'
	ant -f $guitar_build_file jfc.dist
fi

echo
## END BUILDING PROJECT

if [ ! -d $aut_path ]; then
	echo 'Checking out AUT'
	mkdir -p $aut_path
	svn co https://drjava.svn.sourceforge.net/svnroot/drjava/trunk/drjava@5686 $aut_path
fi

if [ ! -d $aut_path/classes ]; then
	echo 'Building AUT'
	# DrJava needs the env JAVA7_HOME set
	if uname -a | grep i386 ; then
		export JAVA7_HOME=/usr/lib/jvm/java-7-openjdk-i386
	else
		export JAVA7_HOME=/usr/lib/jvm/java-7-openjdk-amd64
	fi

	ant jar -f $aut_build_file
fi

if [ ! -d $aut_inst ]; then
	echo 'Instrumenting classes'
	mkdir -p $aut_inst
	rm -rf $aut_inst/*

	pushd $aut_bin
	cp $aut_path/drjava.jar .
	jar xf drjava.jar
	# This class doesn't have code line information. Cobertura cant' work with it
	# We are removing it till a propper compilation solution is done
	rm edu/rice/cs/drjava/model/compiler/CompilerOptions*
	rm drjava.jar
	popd

	cobertura-instrument --destination $aut_inst $aut_bin/edu/rice/cs/drjava
	cp cobertura.ser cobertura.ser.bkp
fi

if ! $skip_ripping; then
	echo ""
	echo "Ripping the application"

	# Cleaning
	rm -rf $gui_file $efg_file $testcases_dir/*

	source $scripts/jfc-ripper.sh -cp $aut_cp -c $mainclass -g $gui_file -cf $configuration -d $ripper_delay -i $intial_wait -l $log_file

	echo "Output directory:  $output_dir"

	# Converting GUI structure to EFG
	echo ""
	echo "About to convert GUI structure file to Event Flow Graph (EFG) file"
	#read -p "Press ENTER to continue..."
	source $scripts/gui2efg.sh -g $gui_file -e $efg_file

	# Generating test cases
	echo ""
	echo "About to generate test cases to cover $tc_no $tc_length-way event interactions"

	# -l: Interaction length
	# -m: Number of test cases to generate, 0 for all possibile test cases.
	source $scripts/tc-gen-random.sh -e $efg_file -l $tc_length -m $tc_no -d $testcases_dir
fi

# Replaying generated test cases
echo ""
echo "About to replay test case(s)"

if [ -z $tc_no ]; then
		testcase_num=1000000 # what a big number :)
	else
		testcase_num=$tc_no
fi

# Cleaning
rm -rf $reports_path/*


counter=0
total=`ls -l $testcases_dir | wc -l`

for testcase in `find $testcases_dir -name "*.tst"| sort -R| head -n$testcase_num`
do
	source $workspace/progress_bar.sh $counter++ $total

	# getting the original cobertura.ser
	rm $workspace/cobertura.ser
	cp $workspace/cobertura.ser.bkp $workspace/cobertura.ser

	# getting test name
	test_name=`basename $testcase`
	test_name=${test_name%.*}

	cmd="$scripts/jfc-replayer.sh -cp $aut_cp -c  $mainclass -g $gui_file -e $efg_file -t $testcase -i $intial_wait -d $relayer_delay -l $logs_dir/$test_name.log -gs $states_dir/$test_name.sta -cf $configuration -ts"

	# adding application arguments if needed
	if [ ! -z $args ]
	then
		cmd="$cmd -a \"$args\" "
	fi
	source $cmd > /dev/null

	cobertura-report --format xml --destination $reports_path > /dev/null
	mv $reports_path/coverage.xml $reports_path/$test_name.xml
done

perl ./matrix-gen.perl

echo
echo LINK TO THE HTML MATRIX: file://`dirname $0`/reports/html/matrix.html
echo