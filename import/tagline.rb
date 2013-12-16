module Importer
  class Tagline
    COLUMNS = ["id", "movie_id", "tagline"]
    REL_CLASS="MovieTagline"

    def initialize(importer, filename)
      @imp = importer
      @file = filename
      import
    end

    def import
      File.open(@file, "r:utf-8").each_line do |line|
        line.chomp!
        data = Hash[COLUMNS.zip(line.split(/\t/))]
        query_data = data.get(["tagline"])
        data.to_int!(["id", "movie_id"])
        data.remove_blanks!
        movie_node = data["movie_id"]
        data.remove!(["movie_id"])
        @imp.solr_add("movie", movie_node, query_data)
      end
    end
  end
end
