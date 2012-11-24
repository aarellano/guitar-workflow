#!/usr/bin/ruby
require 'trollop'
require 'mysql'
require 'fileutils'
require 'find'

require_relative "etr"
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
	opt :wtc, "Number of test cases to write from the EFG. If 0 then all the possible TC are written. If -1 no test cases are written. All the previous test cases are discarted", default: -1
	opt :dev, "This option uses a development table when writing coverages and faults to database.", default: true
	opt :manual, "With this option the AUT can be run manually, without automated tests"
	opt :faults, "This flag enable the fault matrix generation", default: false
	opt :faults_file, "This file should have all the faults", type: :string
	opt :instance, "This option is used to specify a custom instance name, used for coverage and faults tables and persistent directories when --no-dev is set. The postfix used by default is the current time.", type: :string
	opt :workspace, "This is the path to be used as the workspace. It overrides the environment var WORKSPACE used by Jenkins", type: :string
	opt :clean, "When this option is enabled, the directories and tables associated with the current instance are deleted"
end

workspace = opts.workspace ? opts.workspace : (ENV['WORKSPACE'] ? ENV['WORKSPACE'] : Dir.pwd)
aut_name = "drjava"
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
guitar_root = "#{workspace}/guitar"
guitar_build_file = "#{guitar_root}/build.xml"
guitar_jfc = "#{guitar_root}/dist/guitar"
guitar_jfc_lib = "#{guitar_jfc}/jars"
output_dir = opts.instance ? "#{workspace}/output_#{opts.instance}" : (opts.dev ? "#{workspace}/output" : ("#{workspace}/output_#{Time.now.strftime("%Y%m%d%H%M%S")}"))
gui_file = "#{output_dir}/DrJava.GUI"
efg_file = "#{output_dir}/DrJava.EFG"
log_file = "#{output_dir}/DrJava.log"
testcases_dir = "#{output_dir}/testcases"
states_dir = "#{output_dir}/states"
logs_dir = "#{output_dir}/logs"
ripper_delay = 500
tc_length = 2
relayer_delay = 200
intial_wait = 2000

faulty_world = "#{workspace}/faulty_world"
faulty_root = "#{faulty_world}/#{aut_name}"
faulty_output = opts.instance ? "#{faulty_world}/output_#{opts.instance}" : (opts.dev ? "#{faulty_world}/output" : ("#{faulty_world}/output_#{Time.now.strftime("%Y%m%d%H%M%S")}"))
faulty_logs = "#{faulty_output}/logs"
faulty_states = "#{faulty_output}/states"

ENV['JAVA7_HOME'] = `uname -a | grep i386` != "" ? '/usr/lib/jvm/java-7-openjdk-i386' : '/usr/lib/jvm/java-7-openjdk-amd64'
table_postfix = opts.instance ? opts.instance : (opts.dev ? "devmode" : "#{Time.now.strftime("%Y%m%d%H%M%S")}")

if ! File.directory? guitar_root
	puts 'Checking out GUITAR source'
	FileUtils.mkdir_p guitar_root
	`svn co https://guitar.svn.sourceforge.net/svnroot/guitar/trunk@3320 #{guitar_root}`
end

if ! File.directory? guitar_jfc
	puts 'Building the GUITAR target jfc.dist'
	`ant -f #{guitar_build_file} jfc.dist`
	# This jar is outdated, and causes problems if not removed
	FileUtils.rm_rf  "#{guitar_jfc}/jars/cobertura.jar"
end

if ! File.directory? aut_root
	puts 'Checking out AUT'
	FileUtils.mkdir_p aut_root
	`svn co https://drjava.svn.sourceforge.net/svnroot/drjava/trunk/drjava@5686 #{aut_root}`
end

if ! File.directory? aut_bin
	puts 'Building AUT'
	FileUtils.mkdir_p aut_bin
	if (`uname -a | grep i386`) != ""
		ENV['JAVA7_HOME'] = '/usr/lib/jvm/java-7-openjdk-i386'
	else
		ENV['JAVA7_HOME'] = '/usr/lib/jvm/java-7-openjdk-amd64'
	end
	`ant jar -f #{aut_build_file}`
end

if ! File.directory? aut_inst
	puts 'Instrumenting classes'
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
Dir["#{guitar_jfc_lib}/**/*.jar"].each { |jar| classpath << ':' + jar }

if opts.rip
	guitar_opts = '-Dlog4j.configuration=log/guitar-clean.glc'
	guitar_args = "-c #{aut_mainclass} -g #{gui_file} -cf #{aut_config} -d #{ripper_delay} -i #{intial_wait} -l #{log_file}"

	puts "Ripping the application"
	rip_cmd = "java -Duser.home=#{workspace}/tmp #{guitar_opts} -cp #{classpath} edu.umd.cs.guitar.ripper.JFCRipperMain #{guitar_args}"
	rip_cmd.insert(0, 'xvfb-run -a ') if opts.xvfb
	`#{rip_cmd}`

	puts "Converting GUI structure file to Event Flow Graph (EFG) file"
	`java #{guitar_opts} -cp #{classpath} edu.umd.cs.guitar.graph.GUIStructure2GraphConverter -p EFGConverter -g #{gui_file} -e #{efg_file}`
end

if opts.wtc >= 0
	puts "Generating test cases to cover #{opts.wtc == 0 ? 'all' : opts.wtc} #{tc_length}-way event interactions"
	`java #{guitar_opts} -cp #{classpath} edu.umd.cs.guitar.testcase.TestCaseGenerator -p RandomSequenceLengthCoverage -e #{efg_file} -l #{tc_length} -m #{opts.wtc} -d #{testcases_dir}`
end

if opts.replays >= 0
	puts "Replaying test cases"
	if ! opts.dev || opts.instance
		puts "Trying to resume from previous process: #{table_postfix}"
		if postfix_used? table_postfix
			puts "Previous process with same instance name found. If you want to start it from scratch, use the --clean option before running again"
			resume = true
		else
			puts "No previous process with same instance name found (or it was empty). Creating a new set of tables"
			resume = false
			create_coverage_table(table_postfix)
		end
	end

	FileUtils.mkdir_p output_dir
	FileUtils.mkdir_p states_dir
	FileUtils.mkdir_p logs_dir
	FileUtils.mkdir_p testcases_dir
	total = `ls -l #{testcases_dir} | wc -l`.to_i
	testcase_num = opts.replays == 0 ? total : opts.replays
	ETR.start testcase_num
	Dir[testcases_dir + '/*.tst'].first(testcase_num).each_with_index do |tc, tc_n|
		test_name = File.basename(tc, '.*')

		if resume
			if testcase_already_run? table_postfix, test_name
				puts "Test case number #{tc_n + 1} #{test_name} already run, skipping"
				next
			end
		end

		puts "Running test case #{tc_n + 1}. Estimated time remaining: #{(ETR.run / 3600).round 2} hours "

		FileUtils.rm "#{workspace}/cobertura.ser"
		FileUtils.cp "#{workspace}/cobertura.ser.bkp", "cobertura.ser"

		guitar_opts="-Dlog4j.configuration=log/guitar-clean.glc -Dnet.sourceforge.cobertura.datafile=cobertura.ser"
		guitar_args = "-c #{aut_mainclass} -g #{gui_file} -e #{efg_file} -t #{tc} -i #{intial_wait} -d #{relayer_delay} -l #{logs_dir}/#{test_name}.log -gs #{states_dir}/#{test_name}.sta -cf #{aut_config}"
		replay_cmd = "java #{guitar_opts} -cp #{classpath} edu.umd.cs.guitar.replayer.JFCReplayerMain #{guitar_args}"
		replay_cmd.insert(0, 'xvfb-run -a ') if opts.xvfb
		`#{replay_cmd}`

		`cobertura-report --format xml --destination #{workspace} 2>&1 > /dev/null --datafile #{workspace}/cobertura.ser`
		write_coverage(test_name, workspace + '/coverage.xml', table_postfix)
		FileUtils.rm "#{workspace}/coverage.xml"
	end
	puts "FINISHED. TOTAL TIME REPLAYING TEST CASES: #{(ETR.finish / 3600).round 2} hours"
end

if opts.manual
	puts "Manually running the AUT"
	create_coverage_table(table_postfix)
	`java #{guitar_opts} -cp #{classpath} edu.umd.cs.guitar.replayer.JFCReplayerMain #{guitar_args}`

	`cobertura-report --format xml --destination #{workspace} 2>&1 > /dev/null --datafile #{workspace}/cobertura.ser`
	write_coverage(test_name, workspace + '/coverage.xml', table_postfix)
	FileUtils.rm "#{workspace}/coverage.xml"
end

if opts.faults
	FileUtils.mkdir_p faulty_world if ! File.directory? faulty_world
	FileUtils.mkdir_p faulty_output if ! File.directory? faulty_output
	FileUtils.mkdir_p faulty_states if ! File.directory? faulty_states
	FileUtils.mkdir_p faulty_logs if ! File.directory? faulty_logs

	if ! File.directory? faulty_root
		FileUtils.cp_r aut_root, faulty_world
	end

	faulty_classpath = "#{aut_inst}:#{cobertura_cp}:#{faulty_root}/drjava.jar"
	Dir["#{guitar_jfc_lib}/**/*.jar"].each { |jar| faulty_classpath << ':' + jar }
	create_faults_table(table_postfix)

	ETR.start `wc -l #{opts.faults_file}`.to_i
	IO.readlines(opts.faults_file).each_with_index do |line, f_n|
		puts "Seeding fault number #{f_n + 1}. Estimated time remaining: #{(ETR.run / 3600).round 2} hours"
		split_line = line.split '#'
		faulty_file = "#{faulty_root}/src/#{split_line[0].gsub('.', '/')}/#{split_line[1]}.java"
		test_cases = get_relevant_testcases(table_postfix, split_line[0], split_line[0] + '.' + split_line[1], split_line[2])
		puts "There #{test_cases.num_rows == 1 ? 'is' : 'are'} #{test_cases.num_rows} relevant test cases for this fault"
		next if test_cases.num_rows == 0

		FileUtils.cp faulty_file, faulty_file + '.bkp'
		if split_line[4].chop == "5" # Then removes the entire line
			`sed -i '#{split_line[2]}d' #{faulty_file}`
		else
			`sed -i '#{split_line[2]}c #{split_line[3]}' #{faulty_file}`
		end

		FileUtils.rm_rf "#{faulty_root}/drjava.jar"
		FileUtils.rm_rf "#{faulty_root}/classes"
		puts "Building faulty version"
		ant_jar = `ant jar -f #{faulty_root}/build.xml 2>&1 | grep 'BUILD FAILED'`
		FileUtils.cp faulty_file + '.bkp', faulty_file
		next if ant_jar != ""
		test_cases.each_hash do |row|
			puts "Running test case #{row['tc_name']}"
			guitar_opts="-Dlog4j.configuration=log/guitar-clean.glc -Dnet.sourceforge.cobertura.datafile=cobertura.ser"
			guitar_args = "-c #{aut_mainclass} -g #{gui_file} -e #{efg_file} -t #{testcases_dir}/#{row['tc_name']}.tst -i #{intial_wait} -d #{relayer_delay} -l #{faulty_logs}/#{row['tc_name']}.log -gs #{faulty_states}/#{row['tc_name']}.sta -cf #{aut_config}"
			run_cmd = "java #{guitar_opts} -cp #{faulty_classpath} edu.umd.cs.guitar.replayer.JFCReplayerMain #{guitar_args}"
			run_cmd.insert(0, 'xvfb-run -a ') if opts.xvfb
			`#{run_cmd}`

			`sed 's/^[ \t]*//;s/[ \t]*$//;/milliseconds/d;/^$/d' #{states_dir}/#{row['tc_name']}.sta > 'state'`
			IO.readlines('state').each do |st_line|
				f = open('state_word_sorted','a')
				f.puts st_line.chars.sort.join
				f.close
			end
			`sed 's/^[ \t]*//;s/[ \t]*$//;/^$/d' state_word_sorted > state`
			`sort state -o state`

			`sed 's/^[ \t]*//;s/[ \t]*$//;/milliseconds/d;/^$/d' #{faulty_states}/#{row['tc_name']}.sta > faulty_state`
			IO.readlines('faulty_state').each do |f_line|
				f = open('faulty_state_word_sorted','a')
				f.puts f_line.chars.sort.join
				f.close
			end
			`sed 's/^[ \t]*//;s/[ \t]*$//;/^$/d' faulty_state_word_sorted > faulty_state`
			`sort faulty_state -o faulty_state`

			detection = `diff state faulty_state` != "" ? true : false
			puts "Writing results"
			write_fault(row['tc_name'], f_n + 1, detection, split_line[4], table_postfix)

			`rm state state_word_sorted faulty_state faulty_state_word_sorted`
		end
	end
	puts "FINISHED. TOTAL TIME SEEDING FAULTS: #{(ETR.finish / 3600).round 2} hours"
end

if opts.clean
	puts "Are you sure? [y/n]"
	if gets.chop == "y"
		FileUtils.rm_rf output_dir
		clean table_postfix
	end
end