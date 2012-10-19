require 'mysql'
require 'xmlsimple'

begin
dbh = Mysql.real_connect("localhost", "root", "root", "cs737")
rescue Mysql::Error => e
  puts "Error code: #{e.errno}"
  puts "Error message: #{e.error}"
  puts "Error SQLSTATE: #{e.sqlstate}" if e.respond_to?("sqlstate")
end

dbh.query("DROP TABLE IF EXISTS drjava")
dbh.query("CREATE TABLE drjava(package VARCHAR(100), class VARCHAR(100), line INT, hits INT, primary key (package, class, line))")

xml = XmlSimple.xml_in('coverage.xml', { 'KeyAttr' => 'name' })
table = "drjava"
xml["packages"][0]["package"].each do |package, p_row|
  p_row["classes"][0]["class"].each do |c_name, c_row|
    c_row["lines"][0].each do |line, l_row|
      l_row.each do |info|
        dbh.query "INSERT INTO " + table + " (package, class, line, hits) VALUES('" + package + "','" + c_name + "'," + info["number"] + "," + info["hits"] + ");"
      end
    end
  end
end

dbh.close if dbh