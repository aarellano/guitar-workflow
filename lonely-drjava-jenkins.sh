#!/bin/bash
# This script rips and runs test cases on DrJava using GUITAR

if [ -z $WORKSPACE ]; then
	WORKSPACE='/var/lib/jenkins/workspace/phase2'
fi
AUT_PATH=$WORKSPACE'/drjava'
AUT_BUILD_FILE=$AUT_PATH/'build.xml'
AUT_BIN=$WORKSPACE'/aut_bin'
AUT_INST=$WORKSPACE'/aut_inst'
GUITAR_PATH=$WORKSPACE'/guitar'
GUITAR_BUILD_FILE=$GUITAR_PATH'/build.xml'
# AUT_PATH=`dirname $0`/trunk/dist/guitar/jfc-aut/RadioButton
# AUT_CLASSES=$AUT_PATH/bin
# INSTRUMENTED_CLASSES=`dirname $0`/trunk/dist/guitar/jfc-aut/RadioButton/instrumented-classes
# JFC_DIST_PATH=`dirname $0`/trunk/dist/guitar
# REPORTS_PATH=`dirname $0`/cobertura-reports

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

XFVB=true
MAX_NUM_TESTCASES=2
AUTO_RUN=true
SKIP_RIPPING=false
RUN_TESTS=true
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
		MAX_NUM_TESTCASES=$OPTARG
		;;
	m)
		AUTO_RUN=false
		;;
	r)
		SKIP_RIPPING=true
		;;
	n)
		RUN_TESTS=false
		;;
	\?)
      echo "Invalid option: -$OPTARG" >&2
      	exit 1
		;;
  esac
done

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
# if ! java -version 2>&1 | grep 1.7 ; then PACKAGES+=' openjdk-7-jdk'; fi > /dev/null
if ! which ant ; then PACKAGES+=' ant'; fi > /dev/null
if ! which svn ; then PACKAGES+=' subversion'; fi > /dev/null
if ! which xvfb-run ; then PACKAGES+=' xvfb'; fi > /dev/null
if perl -e 'use XML::Simple;' 2>&1 | grep -q "Can't locate XML"; then PACKAGES+=' libxml-simple-perl'; fi
if ! which cobertura-instrument ; then PACKAGES+=' cobertura'; fi > /dev/null
if [ -n "$PACKAGES" ]; then
	echo 'Updating repositories and packages...'
	sudo apt-get update > /dev/null && sudo apt-get -y upgrade > /dev/null
	echo "Installing new packages: $PACKAGES"
	sudo apt-get -y install $PACKAGES
fi
echo
## END CHECKING FOR REQUIRED SOFTWARE

# if [ ! -d $GUITAR_PATH ]; then
# 	echo 'Checking out GUITAR source'
# 	mkdir -p $GUITAR_PATH
# 	svn co https://guitar.svn.sourceforge.net/svnroot/guitar/trunk@3320 $GUITAR_PATH
# fi

# if [ ! -d $GUITAR_PATH/dist ]; then
# 	echo 'Building the GUITAR target jfc.dist'
# 	ant -f $GUITAR_BUILD_FILE jfc.dist
# fi

	# echo 'Updating cobertura.jar'
	# wget http://sourceforge.net/projects/cobertura/files/cobertura/1.9.4.1/cobertura-1.9.4.1-bin.tar.gz
	# tar -C $JFC_DIST_PATH/jars -xzf cobertura-1.9.4.1-bin.tar.gz
	# rm -f cobertura-1.9.4.1-bin.tar.gz
	# rm -f $JFC_DIST_PATH/jars/cobertura.jar

echo
## END BUILDING PROJECT

if [ ! -d $AUT_PATH ]; then
	echo 'Checking out AUT'
	mkdir -p $AUT_PATH
	svn co https://drjava.svn.sourceforge.net/svnroot/drjava/trunk/drjava@5686 $AUT_PATH
fi

if [ ! -d $AUT_PATH/classes ]; then
	echo 'Building AUT'
	ant -f $AUT_BUILD_FILE
fi

if [ ! -d $AUT_INST ]; then
	echo 'Instrumenting classes'
	mkdir -p $AUT_INST
	mkdir -p $AUT_BIN
	cp $AUT_PATH/drjava.jar $AUT_BIN
	cobertura-instrument --destination $AUT_INST $AUT_BIN/drjava.jar
	cp cobertura.ser cobertura.ser.bkp
fi

## TEMPORARY EARLY EXIT. WIP STEP BY STEP :)
exit 0
##################

common-inst.sh DrJava

echo 'Updating scripts to run cobertura'

echo 'Removing jfc-sample-workflow.sh'
rm -f $JFC_DIST_PATH/jfc-sample-workflow.sh
echo 'Removing jfc-replayer.sh'
rm -f $JFC_DIST_PATH/jfc-replayer.sh
echo 'Rmoving jfc-ripper.sh'
rm -f $JFC_DIST_PATH/jfc-ripper.sh
echo 'Copying new jfc-sample-workflow.sh'
cp modified-scripts/jfc-sample-workflow.sh $JFC_DIST_PATH
echo 'Copying new jfc-replayer.sh'
cp modified-scripts/jfc-replayer.sh $JFC_DIST_PATH
echo 'Copying new jfc-ripper.sh'
cp modified-scripts/jfc-ripper.sh $JFC_DIST_PATH

echo
## END REPLACING SCRIPTS

echo 'Instrumenting classes'
if [ ! -d "$INSTRUMENTED_CLASSES" ]; then
        mkdir -p $INSTRUMENTED_CLASSES
fi
rm -rf $INSTRUMENTED_CLASSES"/*"
rm cobertura.ser # just in case
cobertura-instrument --destination $INSTRUMENTED_CLASSES $AUT_CLASSES
cp cobertura.ser cobertura.ser.bkp


echo
## END INSTRUMENTING CLASSES

echo 'Running tests'
if $RUN_TESTS; then
	if $AUTO_RUN; then
		# First we clean the reports directory
		rm -rf $REPORTS_PATH/*

		. $JFC_DIST_PATH/jfc-sample-workflow.sh
	else
		if $XVFB; then
			xvfb-run -a java -cp $JFC_DIST_PATH/jars/cobertura-1.9.4.1/cobertura.jar:$INSTRUMENTED_CLASSES:$AUT_CLASSES -Dnet.sourceforge.cobertura.datafile=cobertura.ser Project
		else
			java -cp $JFC_DIST_PATH/jars/cobertura-1.9.4.1/cobertura.jar:$INSTRUMENTED_CLASSES:$AUT_CLASSES -Dnet.sourceforge.cobertura.datafile=cobertura.ser Project
		fi
	fi
fi

perl ./matrix-gen.perl

echo
echo LINK TO THE HTML MATRIX: file://`dirname $0`/reports/html/matrix.html
echo