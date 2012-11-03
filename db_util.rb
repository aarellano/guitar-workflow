require 'mysql'
require 'nokogiri'

def create_coverage_table(table_postfix)
  dbh = get_dbh
  dbh.query("DROP TABLE IF EXISTS coverage_#{table_postfix}")
  dbh.query("CREATE TABLE coverage_#{table_postfix}(tc_id INT AUTO_INCREMENT, package_id INT, class_id INT, line INT, hits INT, PRIMARY KEY (tc_id, package_id, class_id, line))")
  dbh.query("DROP TABLE IF EXISTS classes_#{table_postfix}")
  dbh.query("CREATE TABLE classes_#{table_postfix} (id INT AUTO_INCREMENT, class_name VARCHAR(100), PRIMARY KEY (id), UNIQUE INDEX (class_name))")
  dbh.query("DROP TABLE IF EXISTS packages_#{table_postfix}")
  dbh.query("CREATE TABLE packages_#{table_postfix} (id INT AUTO_INCREMENT, package_name VARCHAR(100), PRIMARY KEY (id), UNIQUE INDEX (package_name))")
  dbh.query("DROP TABLE IF EXISTS testcases_#{table_postfix}")
  dbh.query("CREATE TABLE testcases_#{table_postfix} (id INT AUTO_INCREMENT, tc_name VARCHAR(100), PRIMARY KEY (id), UNIQUE INDEX (tc_name))")
  dbh.close if dbh
end

def create_faults_table(table_postfix)
  dbh = get_dbh
  dbh.query("DROP TABLE IF EXISTS faults_#{table_postfix}")
  dbh.query("CREATE TABLE faults_#{table_postfix}(fault INT, tc_id INT, detection BOOL, fault_type INT, PRIMARY KEY (fault, tc_id))")
  dbh.close if dbh
end

def write_coverage(testcase, xml_file, table_postfix)
  dbh = get_dbh
  dbh.query("INSERT IGNORE INTO testcases_#{table_postfix} (tc_name) VALUES ('#{testcase}')")
  f = File.open(xml_file)
  xml = Nokogiri::XML(f)
  f.close
  values = ''
  counter = 0
  xml.xpath("//packages/package").each do |p|
    dbh.query("INSERT IGNORE INTO packages_#{table_postfix} (package_name) VALUES ('#{p['name']}')")
    p.xpath("classes/class").each do |c|
      dbh.query("INSERT IGNORE INTO classes_#{table_postfix} (class_name) VALUES ('#{c['name'].gsub(/\$.*/,'')}')")
      c.xpath("lines/line").each do |l|
        if ((l['hits']).to_i > 0)
          values += ',' unless counter == 0
          tc_id = dbh.query("SELECT id FROM testcases_#{table_postfix} WHERE tc_name = '#{testcase}'").fetch_hash['id']
          package_id = dbh.query("SELECT id FROM packages_#{table_postfix} WHERE package_name = '#{p['name']}'").fetch_hash['id']
          class_id = dbh.query("SELECT id FROM classes_#{table_postfix} WHERE class_name = '#{c['name'].gsub(/\$.*/,'')}'").fetch_hash['id']
          values += "(#{tc_id}, #{package_id}, #{class_id}, #{l['number']}, #{l['hits']})"
          if (counter += 1) == 10000
            dbh.query "INSERT INTO coverage_#{table_postfix} (tc_id, package_id, class_id, line, hits) VALUES #{values};"
            values = ''
            counter = 0
          end
        end
      end
    end
  end
  dbh.query "INSERT INTO coverage_#{table_postfix} (tc_id, package_id, class_id, line, hits) VALUES #{values};" if values != ''
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

def get_relevant_testcases(table_postfix, package, class_name, line)
  dbh = get_dbh
  return dbh.query "SELECT tc_name FROM testcases_#{table_postfix} WHERE
  id IN (SELECT id FROM coverage_#{table_postfix} WHERE
    package_id =  (SELECT id FROM packages_#{table_postfix} WHERE package_name = '#{package}')
    AND class_id = (SELECT id FROM classes_#{table_postfix} WHERE class_name = '#{class_name}')
    AND line = #{line})"
end

def write_fault(testcase, fault_number, detection, fault_type, table_postfix)
  dbh = get_dbh
  tc_id = dbh.query("SELECT id FROM testcases_#{table_postfix} WHERE tc_name = '#{testcase}'").fetch_hash['id']
  dbh.query "INSERT INTO faults_#{table_postfix} (fault, tc_id, detection, fault_type) VALUES (#{fault_number}, #{tc_id}, #{detection}, #{fault_type})"
  dbh.close if dbh
end