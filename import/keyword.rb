module Importer
  class Keyword
    NODE_COLUMNS = ["id", "keyword"]
    REL_COLUMNS = ["id", "movie_id", "keyword_id"]
    CLASS="Keyword"
    REL_CLASS="MovieKeyword"
    AWARDS = ["awards-show", "awards"]

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
        @imp.store_data("keyword", data["id"], data["keyword"])
      end
    end

    def import_relations
      movie_award = {}
      File.open(@relation_file, "r:utf-8").each_line do |line|
        line.chomp!
        data = Hash[REL_COLUMNS.zip(line.split(/\t/))]
        data.to_int!(["id", "movie_id", "keyword_id"])
        data.remove_blanks!
        plots = @imp.fetch_data("plot", data["movie_id"])
        keyword = @imp.fetch_data("keyword", data["keyword_id"]).dup
        movie_node = data["movie_id"]
        keyword_node = data["keyword_id"]
        data.remove!(["id", "movie_id", "keyword_id"])
        data["strong"] = check_strong(keyword, plots)
        data["keyword"] = keyword
        data.remove!(["class"])
#        data["keyword"].gsub!(/-/," ")
        movie_award[movie_node] = true if AWARDS.include?(data["keyword"])
        @imp.solr_add("movie", movie_node, data)
      end
      movie_award.keys.each do |movie_node|
        @imp.solr_add("movie", movie_node, {"award_keyword" => true})
      end
    end

    def check_strong(keyword, plots)
      strong = false
      kw = keyword.downcase.gsub("-", " ").gsub(/[^ a-z0-9]/, "")
      plots = [plots].compact unless plots.is_a?(Array)
      plots.each do |plot|
        plot = plot.downcase.gsub("-", " ").gsub(/[^ a-z0-9]/, "")
        strong = true if plot.index(kw)
      end
      strong
    end
  end
end
