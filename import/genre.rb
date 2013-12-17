module Importer
  class Genre
    NODE_COLUMNS = ["id", "genre"]
    REL_COLUMNS = ["id", "movie_id", "genre_id"]
    CLASS="Genre"
    REL_CLASS="MovieGenre"
    REDUCE = ["Adult"]

    def initialize(importer, filenames)
      @node_file = filenames[0]
      @relation_file = filenames[1]
      @imp = importer
      import_nodes
      import_relations
    end

    def import_nodes
      File.open(@node_file, "r:utf-8").each_line do |line|
        line.chomp!
        data = Hash[NODE_COLUMNS.zip(line.split(/\t/))]
        data.to_int!(["id"])
        data.remove_blanks!
        @imp.store_data("genre", data["id"], data["genre"])
      end
    end

    def import_relations
      movie_reduce = {}
      File.open(@relation_file, "r:utf-8").each_line do |line|
        line.chomp!
        data = Hash[REL_COLUMNS.zip(line.split(/\t/))]
        data.to_int!(["id", "movie_id", "genre_id"])
        data.remove_blanks!
        genre = @imp.fetch_data("genre", data["genre_id"]).dup
        movie_node = data["movie_id"]
        genre_node = data["genre_id"]
        data.remove!(["id", "movie_id", "genre_id"])
        data["genre"] = genre
        data.remove!(["class"])
        movie_reduce[movie_node] = true if REDUCE.include?(data["genre"])
        @imp.store_data("movie_reduce", movie_node, true);
        @imp.solr_add("movie", movie_node, data)
      end
      movie_reduce.keys.each do |movie_node|
        @imp.solr_add("movie", movie_node, {"reduce_genre" => true})
      end
    end
  end
end
