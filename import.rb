#!/usr/bin/env ruby

$: << "."
require 'import/importer'
require 'import/base'
require 'import/movie'
require 'import/plot'
require 'import/tagline'
require 'import/keyword'
require 'import/genre'
require 'import/person'
require 'import/language'
require 'import/trivia'
require 'import/goof'
require 'import/quote'
require 'import/soundtrack_title'
require 'import/alternate_version'
require 'import/movie_connection'

if __FILE__ == $0
  datadir = ARGV[0] || "shortdata"
  imp = Importer::Import.new

  Importer::Movie.new(imp, [datadir+"/movies.dat", datadir+"/ratings.dat",
                        datadir+"/complete_casts.dat", datadir+"/complete_crews.dat",
                        datadir+"/movie_akas.dat", datadir+"/movie_years.dat",
                        datadir+"/release_dates.dat", datadir+"/running_times.dat",
                        datadir+"/color_infos.dat", datadir+"/certificates.dat",
                        datadir+"/technicals.dat"
                      ])
  Importer::MovieConnection.new(imp, [datadir+"/movie_connections.dat", datadir+"/movie_connection_texts.dat"])
  Importer::Tagline.new(imp, datadir+"/taglines.dat")
  Importer::Genre.new(imp, [datadir+"/genres.dat", datadir+"/movie_genres.dat"])
  Importer::Language.new(imp, [datadir+"/languages.dat", datadir+"/movie_languages.dat"])
  Importer::Person.new(imp, [datadir+"/people.dat", datadir+"/aka_names.dat", datadir+"/occupations.dat", datadir+"/person_metadata.dat"])
  Importer::Plot.new(imp, datadir+"/plots.dat")
  Importer::Keyword.new(imp, [datadir+"/keywords.dat", datadir+"/movie_keywords.dat"])
  Importer::Trivia.new(imp, datadir+"/trivia.dat")
  Importer::Goof.new(imp, datadir+"/goofs.dat")
  Importer::Quote.new(imp, [datadir+"/quotes.dat", datadir+"/quote_data.dat"])
  Importer::SoundtrackTitle.new(imp, [datadir+"/soundtrack_titles.dat", datadir+"/soundtrack_title_data.dat"])
  Importer::AlternateVersion.new(imp, datadir+"/alternate_versions.dat")
end


#*aka_names.dat
#*alternate_versions.dat
#*certificates.dat
#*color_infos.dat
#*complete_casts.dat
#*complete_crews.dat
#*genres.dat
#*goofs.dat
#*keywords.dat
#*languages.dat
#*movie_akas.dat
#*movie_connection_texts.dat
#*movie_connections.dat
#*movie_genres.dat
#*movie_keywords.dat
#*movie_languages.dat
#*movie_years.dat
#*movies.dat
#*occupations.dat
#*people.dat
#*person_metadata.dat
#*plots.dat
#*quote_data.dat
#*quotes.dat
#*ratings.dat
#*release_dates.dat
#*running_times.dat
#*soundtrack_title_data.dat
#*soundtrack_titles.dat
#*taglines.dat
#*technicals.dat
#*trivia.dat
