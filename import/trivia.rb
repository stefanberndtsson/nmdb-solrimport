module Importer
  class Trivia
    COLUMNS = ["id", "movie_id", "spoiler", "trivia", "trivia_norm"]
    CLASS="Trivia"
    REL_CLASS="MovieTrivia"

    def initialize(importer, filename)
      @imp = importer
      @file = filename
      import
    end

    def import
      File.open(@file, "r:utf-8").each_line do |line|
        line.chomp!
        data = Hash[COLUMNS.zip(line.split(/\t/))]
        query_data = data.get(["trivia_norm"])
        data.to_int!(["id", "movie_id"])
        data.to_bool!(["spoiler"])
        data.remove_blanks!
        movie_node = data["movie_id"]
        data.remove!(["movie_id", "trivia_norm"])
        query_data.rename_keys!({"trivia_norm" => "trivia"})
        @imp.solr_add("movie", movie_node, query_data)
      end
    end
  end
end
