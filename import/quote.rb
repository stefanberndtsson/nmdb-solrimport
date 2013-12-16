module Importer
  class Quote
    QUOTE_COLUMNS = ["id", "movie_id", "sort_value"]
    QUOTE_DATA_COLUMNS = ["id", "quote_id", "quote", "sort_value", "quote_norm"]
    CLASS="Quote"
    REL_CLASS="MovieQuote"
    DATA_CLASS="QuoteData"
    DATA_REL_CLASS="QuoteQuoteData"

    def initialize(importer, filenames)
      @quote_file = filenames[0]
      @quote_data_file = filenames[1]
      @imp = importer
      import_quotes
      import_quote_data
    end

    def import_quotes
      File.open(@quote_file, "r:utf-8").each_line do |line|
        line.chomp!
        data = Hash[QUOTE_COLUMNS.zip(line.split(/\t/))]
        data.to_int!(["id", "movie_id"])
        data.copy_to_int!({"sort_value" => "sort_integer"})
        data.remove_blanks!
        movie_node = data["movie_id"]
        data.remove!(["movie_id"])
        @imp.xxstore_data("quote_movie_node", data["id"], movie_node)
      end
    end

    def import_quote_data
      File.open(@quote_data_file, "r:utf-8").each_line do |line|
        line.chomp!
        data = Hash[QUOTE_DATA_COLUMNS.zip(line.split(/\t/))]
        query_data = data.get(["quote_norm"])
        data.to_int!(["id", "quote_id"])
        data.copy_to_int!({"sort_value" => "sort_integer"})
        data.remove_blanks!
        quote_node = data["quote_id"]
        movie_node = @imp.xxfetch_data("quote_movie_node", data["quote_id"])
        data.remove!(["quote_id", "quote_norm"])
        query_data.rename_keys!({"quote_norm" => "quote"})
        @imp.solr_add("movie", movie_node, query_data)
      end
    end
  end
end
