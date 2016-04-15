all: country_level provinces_level autonomies_level

dep:
	cd scripts; bundle install; cd ..;

country_level: dep
	cd scripts; ruby country_level.rb; cd ..;

provinces_level: dep
	cd scripts; ruby provinces_level.rb; cd ..;

autonomies_level: dep
	cd scripts; ruby autonomies_level.rb; cd ..;

