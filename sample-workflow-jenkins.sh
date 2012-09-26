#!/bin/bash
# This script enables and runs a simple sample example workflow on using GUITAR

BUILD_PATH=$PWD/trunk/dist
BUILD_FILE=$PWD/trunk/build.xml
AUT_PATH=$PWD/trunk/dist/guitar/jfc-aut/RadioButton
AUT_CLASSES=$AUT_PATH/bin
INSTRUMENTED_CLASSES=$PWD/trunk/dist/guitar/jfc-aut/RadioButton/instrumented-classes
JFC_DIST_PATH=$PWD/trunk/dist/guitar
REPORTS_PATH=$PWD/cobertura-reports

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
if ! groups | grep 'root\|admin\|sudo' > /dev/null ; then
	echo 'You need to run this script as root, or better yet, using passwordless sudo'
	exit 1
else
	echo 'OK'
fi
echo
## END CHECKING FOR ADMINISTRATIVE PRIVILEGES

echo 'Checking for required software'
if ! which java ; then PACKAGES+=' openjdk-6-jdk'; fi > /dev/null
if ! which ant ; then PACKAGES+=' ant'; fi > /dev/null
if ! which svn ; then PACKAGES+=' subversion'; fi > /dev/null
if ! which xvfb-run ; then PACKAGES+=' xvfb'; fi > /dev/null
if ! which cobertura-instrument ; then PACKAGES+=' cobertura'; fi > /dev/null
if [ -n "$PACKAGES" ]; then
	echo 'Updating repositories and packages...'
	sudo apt-get update > /dev/null && sudo apt-get -y upgrade > /dev/null
	echo "Installing new packages: $PACKAGES"
	sudo apt-get -y install $PACKAGES
fi
echo
## END CHECKING FOR REQUIRED SOFTWARE

echo 'Checking out GUITAR source'
if [ ! -d "$PWD/trunk" ]; then
	svn co https://guitar.svn.sourceforge.net/svnroot/guitar/trunk@3320
fi

echo 'Building project'
if [ -d "$BUILD_PATH" ]; then
        echo 'Project already built. Skipping invocation to ant'
else
        echo 'Building the project jfc.dist'
        ant -f $BUILD_FILE jfc.dist

        echo 'Updating cobertura.jar'
        wget http://sourceforge.net/projects/cobertura/files/cobertura/1.9.4.1/cobertura-1.9.4.1-bin.tar.gz
        tar -C $JFC_DIST_PATH/jars -xzf cobertura-1.9.4.1-bin.tar.gz
        rm -f cobertura-1.9.4.1-bin.tar.gz
	rm -f $JFC_DIST_PATH/jars/cobertura.jar
fi

echo
## END BUILDING PROJECT

echo 'Updating scripts to run cobertura'

echo 'Removing jfc-sample-workflow.sh'
rm -f $JFC_DIST_PATH/jfc-sample-workflow.sh
echo 'Removing jfc-replayer.sh'
rm -f $JFC_DIST_PATH/jfc-replayer.sh
echo 'Copying new jfc-sample-workflow.sh'
cp modified-scripts/jfc-sample-workflow.sh $JFC_DIST_PATH
echo 'Copying new jfc-replayer.sh'
cp modified-scripts/jfc-replayer.sh $JFC_DIST_PATH

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

perl ./matrix.perl

echo
## END RUNNING TESTS