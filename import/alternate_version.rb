module Importer
  class AlternateVersion
    ALTERNATE_VERSION_COLUMNS = ["id", "movie_id", "alternate_version_parent_id", "spoiler", "alternate_version"]
    CLASS="AlternateVersion"
    REL_CLASS="MovieAlternateVersion"
    AV_REL_CLASS="AlternateVersionData"

    def initialize(importer, filename)
      @file = filename
      @imp = importer
      import_alternate_versions
    end

    def import_alternate_versions
      sort_cnt = 0
      File.open(@file, "r:utf-8").each_line do |line|
        line.chomp!
        sort_cnt += 1
        data = Hash[ALTERNATE_VERSION_COLUMNS.zip(line.split(/\t/))]
        data.to_int!(["id", "movie_id", "alternate_version_parent_id"])
        data.to_bool!(["spoiler"])
        data["sort_integer"] = sort_cnt
        data.remove_blanks!
        movie_node = data["movie_id"]
        data.remove!(["movie_id", "alternate_version_parent_id"])
        data.remove!(["id"])
        @imp.solr_add("movie", movie_node, data)
      end
    end
  end
end
