#!/bin/bash

classpath="$guitar_lib/gui-model-core.jar"
for file in `find $guitar_lib -name '*.jar'`
do
	classpath=$classpath:$file
done
classpath=$classpath:$base_dir

# Change GUITAR_OPTS variable to run with the clean log file
guitar_opts="$guitar_opts -Dlog4j.configuration=log/guitar-clean.glc"

JAVA_CMD_PREFIX="java"

main_class=edu.umd.cs.guitar.graph.GUIStructure2GraphConverter

if [ `uname -s | grep -i cygwin | wc -c` -gt 0 ]
then
	classpath=`cygpath -wp $classpath`
fi

$JAVA_CMD_PREFIX $guitar_opts -cp $classpath $main_class  -p EFGConverter $@




