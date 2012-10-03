#!/bin/bash
##################################
# GUITAR tc-gen.sh
##################################
function usage {
	echo "Usage: tc-gen.sh -e <EFG file> -l <length> -m <maximum number> -d
        <tc-dir> [-D no-duplicate-event] [-T treat-terminal-event-specially]"
}

# Main classes
tcgen_launcher=edu.umd.cs.guitar.testcase.TestCaseGenerator

for file in `find $guitar_lib/ -name "*.jar"`
do
	guitar_classpath=${file}:${guitar_classpath}
done

# Change guitar_opts variable to run with the clean log file
guitar_opts="$guitar_opts -Dlog4j.configuration=log/guitar-clean.glc"

plugin=RandomSequenceLengthCoverage

classpath=$guitar_classpath:$base_dir

if [ `uname -s | grep -i cygwin | wc -c` -gt 0 ]
then
	classpath=`cygpath -wp $classpath`
fi

java $guitar_opts -cp $classpath $tcgen_launcher -p $plugin $@





