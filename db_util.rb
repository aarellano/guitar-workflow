require 'mysql'
require 'nokogiri'

def create_coverage_table(table_name)
  dbh = get_dbh
  dbh.query("DROP TABLE IF EXISTS #{table_name}")
  dbh.query("CREATE TABLE #{table_name}(testcase VARCHAR(100), package VARCHAR(100), class VARCHAR(100), line INT, hits INT, PRIMARY KEY (testcase, package, class, line))")
  dbh.close if dbh
end

def create_faults_table(table_name)
  dbh = get_dbh
  dbh.query("DROP TABLE IF EXISTS #{table_name}")
  dbh.query("CREATE TABLE #{table_name}(fault INT, testcase VARCHAR(100), detection BOOL, PRIMARY KEY (fault, testcase))")
  dbh.close if dbh
end

def write_coverage(testcase, xml_file, table_name)
  dbh = get_dbh

  f = File.open(xml_file)
  xml = Nokogiri::XML(f)
  f.close

  xml.xpath("//packages/package").each do |p|
    p.xpath("classes/class").each do |c|
      c.xpath("lines/line").each do |l|
        dbh.query "INSERT INTO #{table_name} (testcase, package, class, line, hits) VALUES ('#{testcase}', '#{p['name']}', '#{c['name']}', #{l['number']}, #{l['hits']});"
      end
    end
  end
  dbh.close if dbh
end

def get_dbh()
    begin
    return dbh = Mysql.real_connect("localhost", "root", "root", "cs737")
  rescue Mysql::Error => e
    puts "Error code: #{e.errno}"
    puts "Error message: #{e.error}"
    puts "Error SQLSTATE: #{e.sqlstate}" if e.respond_to?("sqlstate")
  end
end

def get_relevant_testcases(coverage_table, package, class_name, line)
  dbh = get_dbh
  return dbh.query "SELECT testcase FROM #{coverage_table} WHERE (package = '#{package}' AND class = '#{class_name}' AND line = #{line} AND hits > 0)"
end

def write_fault(testcase, fault_number, detection, table_name)
  dbh = get_dbh
  dbh.query "INSERT INTO #{table_name} (fault, testcase, detection) VALUES ('#{testcase}', #{fault_number}, #{detection})"
  dbh.close if dbh
end