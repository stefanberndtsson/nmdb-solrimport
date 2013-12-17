module Importer
  class Plot
    COLUMNS = ["id", "movie_id", "plot", "author", "plot_norm"]
    CLASS="Plot"
    REL_CLASS="MoviePlot"

    def initialize(importer, filename)
      @imp = importer
      @file = filename
      import
    end

    def import
      File.open(@file, "r:utf-8").each_line do |line|
        line.chomp!
        data = Hash[COLUMNS.zip(line.split(/\t/))]
        query_data = data.get(["plot_norm"])
        data.to_int!(["id", "movie_id"])
        data.remove_blanks!
        next if !data["plot"] || data["plot"].empty?
        movie_node = data["movie_id"]
        @imp.store_data("plot", data["movie_id"], query_data["plot_norm"], :append)
        data.remove!(["movie_id", "plot_norm"])
        query_data.rename_keys!({"plot_norm" => "plot"})
        @imp.solr_add("movie", movie_node, query_data)
      end
    end
  end
end
