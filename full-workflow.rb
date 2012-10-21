#!/usr/bin/ruby
require 'trollop'
require 'mysql'
require 'fileutils'
require 'find'

require_relative "db_util"

opts = Trollop::options do
	banner <<-EOS
	This script rips and runs test cases on DrJava using GUITAR

	SOFTWARE REQUIREMENTS
	debian packages: ant, subversion, xvfb, mysql-server, >ruby1.9.1, cobertura, openjdk-7-jdk
	ruby gems: trollop, mysql

	Usage:
	testing-workflow.rb [options] <faults_file> <aut_src_path>
	where [options] are:
	EOS

	opt :xvfb, "By default xvfb is used to perform all graphical operations in memory. If disabled, the graphics will be shown on a standard X11 server", default: true
	opt :replays, "Maximum number of test cases to write and replay. If 0 all the test cases are run. If -1 no test cases are run", default: -1
	opt :rip, "This option enables ripping the AUT", default: false
	opt :dev, "This option uses a development table when writing to the database.", default: true
	opt :manual, "With this option the AUT can be run manually, without automated tests"
end

workspace = "/var/lib/jenkins/workspace/phase2" if ! ENV['WORKSPACE']
aut_root = "#{workspace}/drjava"
aut_cp = "#{aut_root}/drjava.jar"
aut_src = "#{aut_root}/src"
aut_build_file = "#{aut_root}/build.xml"
aut_bin = "#{aut_root}/classes"
aut_jar = "#{aut_root}/drjava.jar"
aut_inst = "#{workspace}/aut_inst"
aut_config = "#{workspace}/guitar-config/configuration.xml"
aut_mainclass = "edu.rice.cs.drjava.DrJava"
cobertura_cp = "/usr/share/java/cobertura.jar"
reports = "#{workspace}/cobertura-reports"
guitar_root = "#{workspace}/guitar"
guitar_build_file = "#{workspace}/build.xml"
guitar_jfc = "#{workspace}/guitar/dist/guitar"
guitar_jfc_lib = "#{guitar_jfc}/jars"
output_dir = "#{workspace}/output"
gui_file = "#{output_dir}/DrJava.GUI"
efg_file = "#{output_dir}/DrJava.EFG"
log_file = "#{output_dir}/DrJava.log"
testcases_dir = "#{output_dir}/testcases"
states_dir = "#{output_dir}/states"
logs_dir = "#{output_dir}/logs"
intial_wait = 2000
ripper_delay = 500
tc_length = 2
relayer_delay = 200

table_name = opts.dev ? "coverage_devmode" : "coverage_#{Time.now.strftime("%Y%m%d%H%M%S")}"

if ! File.directory? guitar_root
	p 'Checking out GUITAR source'
	FileUtils.mkdir_p guitar_root
	`svn co https://guitar.svn.sourceforge.net/svnroot/guitar/trunk@3320 guitar_root`
end

if ! File.directory? guitar_jfc
	p 'Building the GUITAR target jfc.dist'
	`ant -f #{guitar_build_file} jfc.dist`
	# This jar is outdated, and causes problems if not removed
	FileUtils.rm_rf  "#guitar_jfc/jars/cobertura.jar"
end

if ! File.directory? aut_root
	p 'Checking out AUT'
	FileUtils.mkdir_p aut_root
	`svn co https://drjava.svn.sourceforge.net/svnroot/drjava/trunk/drjava@5686 #{aut_root}`
end

if ! File.directory? aut_bin
	p 'Building AUT'
	FileUtils.mkdir_p aut_bin
	if (`uname -a | grep i386`) != ""
		ENV['JAVA7_HOME'] = '/usr/lib/jvm/java-7-openjdk-i386'
	else
		ENV['JAVA7_HOME'] = '/usr/lib/jvm/java-7-openjdk-amd64'
	end
	`ant jar -f #{aut_build_file}`
end

if ! File.directory? aut_inst
	p 'Instrumenting classes'
	FileUtils.mkdir_p aut_inst
	FileUtils.rm_rf "#{aut_inst}/*"
	FileUtils.cd aut_inst
	FileUtils.cp "#{aut_root}/drjava.jar", '.'
	`jar xf drjava.jar`
	# This class doesn't have code line information. Cobertura cant' work with it
	# Remove it till a propper compilation solution is done
	FileUtils.rm_f 'edu/rice/cs/drjava/model/compiler/CompilerOptions*'
	FileUtils.cd workspace
	FileUtils.rm "#{aut_inst}/drjava.jar"
	`cobertura-instrument --datafile=#{workspace}/cobertura.ser #{aut_inst}/edu/rice/cs/drjava`
	FileUtils.cp 'cobertura.ser', 'cobertura.ser.bkp'
end

classpath = "#{aut_inst}:#{cobertura_cp}:#{aut_cp}"
Dir["/var/lib/jenkins/workspace/phase2/guitar/dist/guitar/jars/**/*.jar"].each { |jar| classpath << ':' + jar }

if opts.rip
	guitar_opts = '-Dlog4j.configuration=log/guitar-clean.glc'
	guitar_args = "-c #{aut_mainclass} -g #{gui_file} -cf #{aut_config} -d #{ripper_delay} -i #{intial_wait} -l #{log_file}"

	p "Ripping the application"
	if opts.xvfb
		`xvfb-run -a java -Duser.home=#{workspace}/tmp #{guitar_opts} -cp #{aut_cp}:#{guitar_jfc_lib} edu.umd.cs.guitar.ripper.JFCRipperMain #{guitar_args}`
	else
		`java -Duser.home=#{workspace}/tmp #{guitar_opts} -cp #{classpath} edu.umd.cs.guitar.ripper.JFCRipperMain #{guitar_args}`
	end

	p "Converting GUI structure file to Event Flow Graph (EFG) file"
	`java #{guitar_opts} -cp #{classpath} edu.umd.cs.guitar.graph.GUIStructure2GraphConverter -p EFGConverter -g #{gui_file} -e #{efg_file}`

	p "Generating test cases to cover #{opts.replays} #{tc_length}-way event interactions"
	`java #{guitar_opts} -cp #{classpath} edu.umd.cs.guitar.testcase.TestCaseGenerator -p RandomSequenceLengthCoverage -e #{efg_file} -l #{tc_length} -m #{opts.replays} -d #{testcases_dir}`
end


if opts.replays >= 0
	p "Replaying test cases"
	create_table(table_name)
	total = `ls -l $testcases_dir | wc -l`
	testcase_num = opts.replays == 0 ? total : opts.replays
	FileUtils.rm_rf reports + '/*'
	counter = 0

	Dir[testcases_dir + '/*.tst'].first(testcase_num).each do |tc|
		counter += 1
		p "Running test case #{counter}"

		FileUtils.rm "#{workspace}/cobertura.ser"
		FileUtils.cp "#{workspace}/cobertura.ser.bkp", "cobertura.ser"

		test_name = File.basename(tc, '.*')
		guitar_opts="-Dlog4j.configuration=log/guitar-clean.glc -Dnet.sourceforge.cobertura.datafile=cobertura.ser"
		guitar_args = "-c #{aut_mainclass} -g #{gui_file} -e #{efg_file} -t #{tc} -i #{intial_wait} -d #{relayer_delay} -l #{logs_dir}/#{test_name}.log -gs #{states_dir}/#{test_name}.sta -cf #{aut_config}"
		if opts.xvfb
			`xvfb-run -a java #{guitar_opts} -cp #{classpath} edu.umd.cs.guitar.replayer.JFCReplayerMain #{guitar_args}`
		else
			`java #{guitar_opts} -cp #{classpath} edu.umd.cs.guitar.replayer.JFCReplayerMain #{guitar_args}`
		end

		`cobertura-report --format xml --destination #{workspace} 2>&1 > /dev/null --datafile #{workspace}/cobertura.ser`
		write_coverage(test_name, workspace + '/coverage.xml', table_name)
		FileUtils.rm "#{workspace}/coverage.xml"
	end
end

if opts.manual
	p "Manually running the AUT"
	create_table(table_name)
	`java #{guitar_opts} -cp #{classpath} edu.umd.cs.guitar.replayer.JFCReplayerMain #{guitar_args}`

	`cobertura-report --format xml --destination #{workspace} 2>&1 > /dev/null --datafile #{workspace}/cobertura.ser`
	write_coverage(test_name, workspace + '/coverage.xml', table_name)
	FileUtils.rm "#{workspace}/coverage.xml"
end