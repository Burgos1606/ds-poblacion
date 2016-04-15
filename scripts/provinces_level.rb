require 'rubygems'
require 'bundler'
require 'open-uri'
require 'csv'
require 'json'

Bundler.require

URL = "http://www.ine.es/jaxiT3/files/t/es/px/2852.px"

def download(url)
  file = Tempfile.new('px')

  open(file.path, 'wb') do |file|
    file << open(url).read.encode!('utf-8', 'iso-8859-15')
  end

  file.path
end

def dump_data_to_json(data)
  file_path = File.expand_path('../data/poblacion-provincias.json', File.dirname(__FILE__))
  puts " - Writting file #{file_path}"

  File.open(file_path, "wb") do |fd|
    data = {
      'population' => data
    }
    fd.write(JSON.dump(data))
  end
end

def dump_data_to_csv(data)
  file_path = File.expand_path('../data/poblacion-provincias.csv', File.dirname(__FILE__))
  puts " - Writting file #{file_path}"

  CSV.open(file_path, "wb") do |csv|
    csv << ['year', 'ine_code', 'name', 'value']
    data.each do |year, provinces_data|
      provinces_data.each do |code, row|
        csv << [year, code, row[:name], row[:value]]
      end
    end
  end
end

puts
puts "Downloading provinces data..."

file_path = download(URL)

dataset = PCAxis::Dataset.new file_path
data = {}
dataset.dimension('Periodo').each do |raw_year|
  year = raw_year.to_i
  data[year] = {}
  dataset.dimension('Provincias').each do |raw_province|
    next if raw_province !~ /\A\d\d\s/

    value = dataset.data('Periodo' => raw_year, 'Provincias' => raw_province, 'Sexo' => 'Total')

    m = raw_province.match(/\A(\d\d)\s(.+)\z/)
    data[year][m[1].to_i] = { name: m[2], value: value.to_f }
  end
end

dump_data_to_csv data
dump_data_to_json data

puts " - Done!"
puts
