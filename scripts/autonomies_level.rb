require 'rubygems'
require 'bundler'
require 'open-uri'
require 'csv'
require 'json'

Bundler.require

URL = "http://www.ine.es/jaxiT3/files/t/es/px/2853.px"

DICTIONARY = {
  "Illes Balears" => 'Baleares',
  "Castilla - La Mancha" => "Castilla-La Mancha",
  "Comunitat Valenciana" => "Comunidad Valenciana"
}

def download(url)
  file = Tempfile.new('px')

  open(file.path, 'wb') do |file|
    file << open(url).read.encode!('utf-8', 'iso-8859-15')
  end

  file.path
end

def dump_data_to_json(data)
  file_path = File.expand_path('../data/poblacion-autonomias.json', File.dirname(__FILE__))
  puts " - Writting file #{file_path}"

  File.open(file_path, "wb") do |fd|
    data = {
      'population' => data
    }
    fd.write(JSON.dump(data))
  end
end

def dump_data_to_csv(data)
  file_path = File.expand_path('../data/poblacion-autonomias.csv', File.dirname(__FILE__))
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

dataset = RubyPx::Dataset.new file_path
data = {}
dataset.dimension('Periodo').each do |raw_year|
  year = raw_year.to_i
  data[year] = {}
  dataset.dimension("Comunidades y Ciudades Autónomas").each do |raw_autonomous_region|
    next if raw_autonomous_region == "Total Nacional"


    if raw_autonomous_region.include?(',')
      p,q = raw_autonomous_region.split(',')
      name = [q.strip,p.strip].join(' ')
    else
      name = raw_autonomous_region
    end
    name = DICTIONARY[name] if DICTIONARY.has_key?(name)

    autonomous_region = INE::Places::AutonomousRegion.find_by_name(name)
    debugger if autonomous_region.nil?

    value = dataset.data('Periodo' => raw_year, "Comunidades y Ciudades Autónomas" => raw_autonomous_region, 'Sexo' => 'Total')

    data[year][autonomous_region.id] = { name: autonomous_region.name, value: value.to_f }
  end
end

dump_data_to_csv data
dump_data_to_json data

puts " - Done!"
puts
