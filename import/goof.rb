module Importer
  class Goof
    COLUMNS = ["id", "movie_id", "category", "spoiler", "goof", "goof_norm"]
    CLASS="Goof"
    REL_CLASS="MovieGoof"

    def initialize(importer, filename)
      @imp = importer
      @file = filename
      import
    end

    def import
      File.open(@file, "r:utf-8").each_line do |line|
        line.chomp!
        data = Hash[COLUMNS.zip(line.split(/\t/))]
        query_data = data.get(["goof_norm"])
        data.to_int!(["id", "movie_id"])
        data.to_bool!(["spoiler"])
        data.remove_blanks!
        movie_node = data["movie_id"]
        data.remove!(["movie_id", "goof_norm"])
        query_data.rename_keys!({"goof_norm" => "goof"})
        @imp.solr_add("movie", movie_node, query_data)
      end
    end
  end
end
