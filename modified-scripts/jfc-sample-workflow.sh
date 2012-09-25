#!/bin/bash

# This is a sample script to demonstrate
# the GUITAR general tesing workflow
# The output can be found in Demo directory

# application classpath
aut_classpath=$JFC_DIST_PATH/jars/cobertura-1.9.4.1/cobertura.jar:$INSTRUMENTED_CLASSES:$AUT_CLASSES

# application main class
mainclass="Project"

# Change the following 2 lines for the classpath and the main class of your
# application. The example is for CrosswordSage, another real world example
# in the jfc-aut directory (http://crosswordsage.sourceforge.net/)

#aut_classpath=$JFC_DIST_PATH/jfc-aut/CrosswordSage/bin:$JFC_DIST_PATH/jfc-aut/CrosswordSage/bin/CrosswordSage.jar
#mainclass="crosswordsage.MainScreen"

#------------------------
# Sample command line arguments
args=""
jvm_options=""

# configuration for the application
# you can specify widgets to ignore during ripping
# and terminal widgets
configuration="$AUT_PATH/guitar-config/configuration.xml"

# intial waiting time
# change this if your application need more time to start
intial_wait=2000

# delay time between two events during ripping
ripper_delay=500

# the length of test suite
tc_length=3

# the maximum number of test case generated (0 means generate all)
tc_no=$MAX_NUM_TESTCASES

# delay time between two events during replaying
# this number is generally smaller than the $ripper_delay
relayer_delay=200

#------------------------
# Output artifacts
#------------------------

# Directory to store all output of the workflow
output_dir=$JFC_DIST_PATH/Demo

# GUI structure file
gui_file="$output_dir/Demo.GUI"

# EFG file
efg_file="$output_dir/Demo.EFG"

# Log file for the ripper
# You can examine this file to get the widget
# signature to ignore during ripping
log_file="$output_dir/Demo.log"

# Test case directory
testcases_dir="$output_dir/testcases"

# GUI states directory
states_dir="$output_dir/states"

# Replaying log directory
logs_dir="$output_dir/logs"

#------------------------
# Main workflow
#------------------------
echo "This script demonstrates a simple testing workflow with GUITAR"
echo "Refer to the document inside the script for more detail on how to customize it"


# Preparing output directories
mkdir -p $output_dir
mkdir -p $testcases_dir
mkdir -p $states_dir
mkdir -p $logs_dir

# Ripping
if ! $SKIP_RIPPING; then
	echo ""
	echo "About to rip the application "
	#read -p "Press ENTER to continue..."
	cmd="$JFC_DIST_PATH/jfc-ripper.sh -cp $aut_classpath -c $mainclass -g  $gui_file -cf $configuration -d $ripper_delay -i $intial_wait -l $log_file"

	# Adding application arguments if needed
	if [ ! -z $args ]
	then
		cmd="$cmd -a \"$args\""
	fi
	echo $cmd
	eval $cmd

	# Converting GUI structure to EFG
	echo ""
	echo "About to convert GUI structure file to Event Flow Graph (EFG) file"
	#read -p "Press ENTER to continue..."
	cmd="$JFC_DIST_PATH/gui2efg.sh -g $gui_file -e $efg_file"
	echo $cmd
	eval $cmd

	# Generating test cases

	echo ""
	echo "About to generate test cases to cover $tc_no $tc_length-way event interactions"
	#read -p "Press ENTER to continue..."

	# -l: Interaction length
	# -m: Number of test cases to generate, 0 for all possibile test cases.
	cmd="$JFC_DIST_PATH/tc-gen-random.sh -e $efg_file -l $tc_length -m $tc_no -d $testcases_dir"



	# Replace tc-gen-random.sh by tc-gen-sq.sh to systematically cover the interactions.
	#cmd="$JFC_DIST_PATH/tc-gen-sq.sh -e $efg_file -l $tc_length -m 0 -d $testcases_dir"

	echo $cmd
	eval $cmd
fi

# Replaying generated test cases
echo ""
echo "About to replay test case(s)"
echo "Enter the number of test case(s): "
#read testcase_num
testcase_num=$tc_no

for testcase in `find $testcases_dir -name "*.tst"| sort -R| head -n$testcase_num`
do
	# getting test name
	test_name=`basename $testcase`
	test_name=${test_name%.*}

	cmd="$JFC_DIST_PATH/jfc-replayer.sh -cp $aut_classpath -c  $mainclass -g $gui_file -e $efg_file -t $testcase -i $intial_wait -d $relayer_delay -l $logs_dir/$test_name.log -gs $states_dir/$test_name.sta -cf $configuration -ts"

	# adding application arguments if needed
	if [ ! -z $args ]
	then
		cmd="$cmd -a \"$args\" "
	fi
	echo $cmd
	eval $cmd

	echo 'Creating cobertura reports'
	cobertura-report --basedir $AUT_CLASSES --format html --destination $REPORTS_PATH/$test_name/html
	cobertura-report --basedir $AUT_CLASSES --format xml --destination $REPORTS_PATH/$test_name/xml
	echo
	## END CREATING COBERTURA REPORTS

done

echo "Output directory:  $output_dir"
