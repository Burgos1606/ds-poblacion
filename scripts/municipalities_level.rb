require 'rubygems'
require 'bundler'
require 'open-uri'
require 'csv'
require 'json'

Bundler.require

def download(url)
  file = Tempfile.new('px')

  open(file.path, 'wb') do |file|
    file << open(url).read.encode!('utf-8', 'iso-8859-15')
  end

  file.path
end

def dump_data_to_json(data)
  file_path = File.expand_path('../data/poblacion-municipios.json', File.dirname(__FILE__))
  puts " - Writting file #{file_path}"

  File.open(file_path, "wb") do |fd|
    data = {
      'population' => data
    }
    fd.write(JSON.dump(data))
  end
end

def dump_data_to_csv(data)
  file_path = File.expand_path('../data/poblacion-municipios.csv', File.dirname(__FILE__))
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
puts "Downloading municipalities data..."

data = {}

2854.upto(2909).each do |file_name|
  url = "http://www.ine.es/jaxiT3/files/t/es/px/#{file_name}.px"
  file_path = download(url)

  dataset = PCAxis::Dataset.new file_path

  # There are files in between the range without data
  next unless dataset.dimensions.include?('Periodo')

  dataset.dimension('Periodo').each do |raw_year|
    year = raw_year.to_i
    data[year] ||= {}
    dataset.dimension('Municipios').each do |raw_province|
      next if raw_province !~ /\A\d{5}\s/

      value = dataset.data('Periodo' => raw_year, 'Municipios' => raw_province, 'Sexo' => 'Total')

      m = raw_province.match(/\A(\d{5})\s(.+)\z/)
      data[year][m[1].to_i] = { name: m[2], value: value.to_f }
    end
  end
end

dump_data_to_csv data
dump_data_to_json data

puts " - Done!"
puts
