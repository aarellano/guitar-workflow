#!/bin/bash
# This script enables and runs a simple sample example workflow on using GUITAR

BUILD_PATH=$PWD/trunk/dist
BUILD_FILE=$PWD/trunk/build.xml
AUT_CLASSES=$PWD/trunk/dist/guitar/jfc-aut/RadioButton/bin
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
		-h 	shows this message
		-x 	by default this script uses xvfb to perform all graphical operations in memory.
			If -x is specified, then the graphics will be shown on a standard X11 server
		-m 	if this flag is set, then the software will run manually (no automated test cases).
		-n	setting this flag, no tests will be run
		"
}

XFVB=true
AUTO_RUN=true
RUN_TESTS=true
while getopts ":h :x :m :n" opt; do
  case $opt in
	h)
		usage
		;;
	x)
		XVFB=false
		;;
	m)
		AUTO_RUN=false
		;;
	n)
		RUN_TESTS=false
		;;
	\?)
      echo "Invalid option: -$OPTARG" >&2
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
        rm cobertura-1.9.4.1-bin.tar.gz
fi

echo
## END BUILDING PROJECT

echo 'Instrumenting classes'
if [ ! -d "$INSTRUMENTED_CLASSES" ]; then
        mkdir -p $INSTRUMENTED_CLASSES
fi
rm -rf $INSTRUMENTED_CLASSES"/*"
rm $JFC_DIST_PATH"/cobertura.ser"
cobertura-instrument --destination $INSTRUMENTED_CLASSES $AUT_CLASSES --datafile $JFC_DIST_PATH"/cobertura.ser"

echo
## END INSTRUMENTING CLASSES

echo 'Running tests'
if $RUN_TESTS; then
	if $AUTO_RUN; then
		. ./jfc-sample-workflow.sh
	else
		if $XVFB; then
			xvfb -a java -cp $JFC_DIST_PATH/jars/cobertura-1.9.4.1/cobertura.jar:$INSTRUMENTED_CLASSES:$AUT_CLASSES -Dnet.sourceforge.datafile=cobertura.ser Project
		else
			java -cp $JFC_DIST_PATH/jars/cobertura-1.9.4.1/cobertura.jar:$INSTRUMENTED_CLASSES:$AUT_CLASSES -Dnet.sourceforge.datafile=cobertura.ser Project
		fi
	fi
fi

echo
## END RUNNING TESTS

echo 'Creating cobertura reports'
rm -rf $REPORT_PATH"/*"
cobertura-report --basedir $AUT_CLASSES --format html --destination $REPORTS_PATH/html
cobertura-report --basedir $AUT_CLASSES --format xml --destination $REPORTS_PATH/xml

echo
## END CREATING COBERTURA REPORTS
