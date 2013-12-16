module Importer
  class Language
    NODE_COLUMNS = ["id", "language"]
    REL_COLUMNS = ["id", "movie_id", "language_id", "info"]
    CLASS="Language"
    REL_CLASS="MovieLanguage"

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
        @imp.xxstore_data("language", data["id"], data["language"])
      end
    end

    def import_relations
      File.open(@relation_file, "r:utf-8").each_line do |line|
        line.chomp!
        data = Hash[REL_COLUMNS.zip(line.split(/\t/))]
        data.to_int!(["id", "movie_id", "language_id"])
        data.remove_blanks!
        language = @imp.xxfetch_data("language", data["language_id"]).dup
        movie_node = data["movie_id"]
        language_node = data["language_id"]
        data.remove!(["id", "movie_id", "language_id"])
        data["language"] = language
        data.remove!(["class"])
        @imp.solr_add("movie", movie_node, data)
      end
    end
  end
end
