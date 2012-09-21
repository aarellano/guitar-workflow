#!/bin/bash
# This script runs a simple sample workflow on using GUITAR

BUILD_PATH=$PWD/trunk/dist
BUILD_FILE=$PWD/trunk/build.xml
TEST_CLASSES=$PWD/trunk/dist/guitar/jfc-aut/RadioButton/bin
INSTRUMENTED_CLASSES=$PWD/trunk/dist/guitar/jfc-aut/RadioButton/instrumented-classes
JFC_DIST_PATH=$PWD/trunk/dist/guitar
REPORTS_PATH=$PWD/cobertura-reports/html


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

echo 'Updating scripts to run cobertura'

echo 'Removing jfc-sample-workflow.sh'
rm -f $JFC_DIST_PATH/jfc-sample-workflow.sh
echo 'Removing jfc-replayer.sh'
rm -f $JFC_DIST_PATH/jfc-replayer.sh
echo 'Copying new jfc-sample-workflow.sh'
cp jfc-sample-workflow.sh $JFC_DIST_PATH
echo 'Copying new jfc-replayer.sh'
cp jfc-replayer.sh $JFC_DIST_PATH

echo
## END REPLACING SCRIPTS

echo 'Instrumenting classes'
if [ ! -d "$INSTRUMENTED_CLASSES" ]; then
        mkdir -p $INSTRUMENTED_CLASSES
fi
rm -rf $INSTRUMENTED_CLASSES"/*"
rm $JFC_DIST_PATH"/cobertura.ser"
cobertura-instrument --destination $INSTRUMENTED_CLASSES $TEST_CLASSES --datafile $JFC_DIST_PATH"/cobertura.ser"

echo
## END INSTRUMENTING CLASSES

echo 'Running tests'
#$JFC_DIST_PATH/jfc-sample-workflow.sh
java -cp $JFC_DIST_PATH/jars/cobertura-1.9.4.1/cobertura.jar:$INSTRUMENTED_CLASSES:$TEST_CLASSES -Dnet.sourceforge.datafile=cobertura.ser Project

echo
## END RUNNING TESTS

echo 'Creating cobertura reports'
rm -rf $REPORT_PATH"/*"
cobertura-report --basedir $TEST_CLASSES --destination $REPORTS_PATH

echo
## END CREATING COBERTURA REPORTS
