require 'rubygems'
require 'bundler'
require 'open-uri'
require 'csv'
require 'json'

Bundler.require

def parse_number(s)
  s.tr('.', '').tr(',', '.').to_f
end

def dump_data_to_json(data)
  file_path = File.expand_path('../data/poblacion-pais.json', File.dirname(__FILE__))
  puts " - Writting file #{file_path}"

  File.open(file_path, "wb") do |fd|
    data = {
      'population' => data
    }
    fd.write(JSON.dump(data))
  end
end

def dump_data_to_csv(data)
  file_path = File.expand_path('../data/poblacion-pais.csv', File.dirname(__FILE__))
  puts " - Writting file #{file_path}"

  CSV.open(file_path, "wb") do |csv|
    csv << ['year', 'value']
    data.each do |year, value|
      csv << [year, value]
    end
  end
end

puts
puts "Downloading country data ..."

page = Nokogiri::HTML(open("http://www.ine.es/prensa/padron_tabla.htm"))

table = page.css('table').detect{|t| t['summary'].include?('Padrón') }

data = {}

table.css('tr')[2..-1].each do |row|
  year       = row.css('td:eq(1)').text.strip
  total      = parse_number(row.css('td:eq(2)').text.strip).to_i
  data[year] = total
end

dump_data_to_csv data
dump_data_to_json data

puts " - Done!"
puts
