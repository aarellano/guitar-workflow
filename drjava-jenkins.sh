#!/bin/bash
# This script does nothing yet...

usage()
{
	echo "
	USAGE
		"
}

XFVB=true
MAX_NUM_TESTCASES=1
AUTO_RUN=true
RUN_TESTS=true
while getopts ":h :x :m :c: :n" opt; do
  case $opt in
	h)
		usage
		exit 0
		;;
	x)
		XVFB=false
		exit 0
		;;
	c)
		MAX_NUM_TESTCASES=$OPTARG
		exit 0
		;;
	m)
		AUTO_RUN=false
		exit 0
		;;
	n)
		RUN_TESTS=false
		exit 0
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
if [ ! -d "$PWD/guitar" ]; then
	svn co https://guitar.svn.sourceforge.net/svnroot/guitar/trunk@3320 guitar
fi

echo 'Checking out DrJava'
if [ ! -d "$PWD/drjava" ]; then
	svn co https://drjava.svn.sourceforge.net/svnroot/drjava/trunk/drjava
fi