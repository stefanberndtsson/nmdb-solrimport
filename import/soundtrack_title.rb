module Importer
  class SoundtrackTitle
    SOUNDTRACK_COLUMNS = ["id", "movie_id", "title", "sort_value"]
    SOUNDTRACK_DATA_COLUMNS = ["id", "soundtrack_title_id", "soundtrack_line", "sort_value"]
    CLASS="SoundtrackTitle"
    REL_CLASS="MovieSoundtrackTitle"
    DATA_CLASS="SoundtrackTitleData"
    DATA_REL_CLASS="SoundtrackTitleSoundtrackTitleData"

    def initialize(importer, filenames)
      @soundtrack_title_file = filenames[0]
      @soundtrack_title_data_file = filenames[1]
      @imp = importer
      import_soundtrack_titles
#      import_soundtrack_title_data
    end

    def import_soundtrack_titles
      File.open(@soundtrack_title_file, "r:utf-8").each_line do |line|
        line.chomp!
        data = Hash[SOUNDTRACK_COLUMNS.zip(line.split(/\t/))]
        data.to_int!(["id", "movie_id"])
        data.copy_to_int!({"sort_value" => "sort_integer"})
        data.remove_blanks!
        movie_node = data["movie_id"]
        data.remove!(["movie_id"])
 #       @imp.xxstore_data("soundtrack_title_movie_node", data["id"], movie_node)
        data.remove!(["id", "class"])
        data.rename_keys!({"title" => "soundtrack_title"})
        @imp.solr_add("movie", movie_node, data)
      end
    end

    def import_soundtrack_title_data
      File.open(@soundtrack_title_data_file, "r:utf-8").each_line do |line|
        line.chomp!
        data = Hash[SOUNDTRACK_DATA_COLUMNS.zip(line.split(/\t/))]
        data.to_int!(["id", "soundtrack_title_id"])
        data.copy_to_int!({"sort_value" => "sort_integer"})
        data.remove_blanks!
        soundtrack_title_node = data["soundtrack_title_id"]
        movie_node = @imp.xxfetch_data("soundtrack_title_movie_node", data["soundtrack_title_id"])
        data.remove!(["soundtrack_title_id"])
      end
    end
  end
end
