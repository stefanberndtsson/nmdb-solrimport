module Importer
  class MovieConnection
    MOVIE_CONNECTION_COLUMNS = ["id", "movie_id", "linked_movie_id", "connection_type_id"]
    MOVIE_CONNECTION_TEXT_COLUMNS = ["id", "movie_id", "linked_movie_id", "connection_type_id", "text", "created_at", "updated_at"]
    CLASS="MovieConnection"

    MC_TYPES = {
      1 => "alternate language version of",
      2 => "edited from",
      3 => "edited into",
      4 => "featured in",
      5 => "features",
      6 => "followed by",
      7 => "follows",
      8 => "referenced in",
      9 => "references",
      10 => "remade as",
      11 => "remake of",
      12 => "spin off from",
      13 => "spin off",
      14 => "spoofed in",
      15 => "spoofs",
      16 => "version of"
    }

    MC_SCORE = {
      1 => [1, 2],
      2 => [1, 2],
      3 => [2, 1],
      4 => [1, 2],
      5 => [2, 1],
      6 => [3, 2],
      7 => [2, 3],
      8 => [2, 1],
      9 => [1, 2],
      10 => [3, 1],
      11 => [1, 3],
      12 => [1, 2],
      13 => [2, 1],
      14 => [3, 1],
      15 => [1, 3],
      16 => [1, 1],
    }

    def initialize(importer, filenames)
      @mc_file = filenames[0]
      @mc_text_file = filenames[1]
      @imp = importer
      @texts = {}
      load_texts
      import_movie_connections
    end

    def load_texts
      File.open(@mc_text_file, "r:utf-8").each_line do |line|
        line.chomp!
        data = Hash[MOVIE_CONNECTION_TEXT_COLUMNS.zip(line.split(/\t/))]
        data.to_int!(["id", "movie_id", "linked_movie_id", "connection_type_id"])
        @texts[[data["movie_id"], data["linked_movie_id"], data["connection_type_id"]]] = [data["text"], data["created_at"], data["updated_at"]]
      end
    end

    def import_movie_connections
      File.open(@mc_file, "r:utf-8").each_line do |line|
        line.chomp!
        data = Hash[MOVIE_CONNECTION_COLUMNS.zip(line.split(/\t/))]
        data.to_int!(["id", "movie_id", "linked_movie_id", "connection_type_id"])
        text_data = @texts[[data["movie_id"], data["linked_movie_id"], data["connection_type_id"]]]
        if text_data
          data["text"] = text_data[0]
          data["created_at"] = text_data[1]
          data["updated_at"] = text_data[2]
        end
        data.remove_blanks!
        movie_node = data["movie_id"]
        linked_movie_node = data["linked_movie_id"]
        data["connection_type"] = MC_TYPES[data["connection_type_id"]]
        link_score = MC_SCORE[data["connection_type_id"]]

        data.remove!(["id", "movie_id", "linked_movie_id", "connection_type_id"])

        data.remove!(["text", "created_at", "updated_at"]) if data["text"] && data["text"] == "[NONE]"

        @imp.xxstore_data("movie_score", movie_node, link_score[0] + @imp.xxfetch_data("movie_score", movie_node).to_i)
        @imp.xxstore_data("movie_score", linked_movie_node, link_score[1] + @imp.xxfetch_data("movie_score", linked_movie_node).to_i)
#        @imp.solr_add("movie", movie_node, data)
#        @imp.solr_add("movie", linked_movie_node, data)
      end
      @imp.xxstored_identifiers("movie_score").each do |key|
        @imp.solr_add("movie", key, {"link_score" => @imp.xxfetch_data("movie_score", key)})
      end
    end
  end
end
