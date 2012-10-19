require 'mysql'
require 'nokogiri'

begin
  dbh = Mysql.real_connect("localhost", "root", "root", "cs737")
rescue Mysql::Error => e
  puts "Error code: #{e.errno}"
  puts "Error message: #{e.error}"
  puts "Error SQLSTATE: #{e.sqlstate}" if e.respond_to?("sqlstate")
end

table = "drjava"
dbh.query("DROP TABLE IF EXISTS drjava")
dbh.query("CREATE TABLE drjava(package VARCHAR(100), class VARCHAR(100), line INT, hits INT, primary key (package, class, line))")

f = File.open("coverage.xml")
xml = Nokogiri::XML(f)
f.close

xml.xpath("//packages/package").each do |p|
  p.xpath("classes/class").each do |c|
    c.xpath("lines/line").each do |l|
      dbh.query "INSERT INTO " + table + " (package, class, line, hits) VALUES('" + p["name"] + "','" + c["name"] + "'," + l["number"] + "," + l["hits"] + ");"
    end
  end
end

dbh.close if dbh