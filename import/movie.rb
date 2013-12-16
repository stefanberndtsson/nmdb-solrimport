require 'date'

module Importer
  class Movie
    COLUMNS = ["id", "full_title", "episode_parent_title", "title", "full_year", "year_open_end", "title_year",
      "title_category", "is_episode", "episode_name", "episode_season", "episode_episode",
      "suspended", "title_norm", "episode_name_norm"]
    RATING_COLUMNS = ["id", "movie_id", "rating", "votes", "vote_distribution"]
    COMPLETENESS_COLUMNS = ["id", "movie_id", "complete_id"]
    YEAR_COLUMNS = ["id", "movie_id", "year"]
    AKA_COLUMNS = ["id", "movie_id", "title", "info", "title_norm"]
    RELEASE_DATE_COLUMNS = ["id", "movie_id", "country", "release_date", "release_stamp", "info"]
    RUNNING_TIME_COLUMNS = ["id", "movie_id", "running_time", "country", "info"]
    COLOR_INFO_COLUMNS = ["id", "movie_id", "color_info", "info"]
    CERTIFICATE_COLUMNS = ["id", "movie_id", "country", "certificate", "info"]
    TECHNICAL_COLUMNS = ["id", "movie_id", "technical_type", "technical_value", "info"]
    CLASS="Movie"
    REL_CLASS="MovieEpisode"
    YEAR_CLASS="MovieYear"
    AKA_CLASS="MovieAka"
    RELEASE_DATE_CLASS="MovieReleaseDate"
    RUNNING_TIME_CLASS="MovieRunningTime"
    COLOR_INFO_CLASS="MovieColorInfo"
    CERTIFICATE_CLASS="MovieCertificate"
    TECHNICAL_CLASS="MovieTechnical"
    CATEGORY_AWARD_VALUE={"M" => 0, "V" => 2, "TV" => 3, "TVS" => 1, "VG" => 0}

    def extract_episode(name)
      episode_name = nil
      episode_season = nil
      episode_episode = nil
      is_episode = false
      position = name.rindex(") {")
      return [name, nil, nil, nil, false] if position.nil?
      episode_data = name[position+3..-2]
      ev_position = episode_data.rindex(" (#")
      if !ev_position && episode_data[0..1] == "(#"
        ev_position = 0
      elsif ev_position
        ev_position += 1
      end
      ev_data = nil
      ep_name = ""
      if ev_position
        ev_data = episode_data[ev_position+2..-2].split(".")
        if ev_data.size != 2
          ev_data = nil
          ev_position = 0
          ep_name = episode_data
        end
        if ev_position > 1
          ep_name = episode_data[0..ev_position-2]
        end
      else
        ep_name = episode_data
      end
      if ep_name && !ep_name.empty?
        episode_name = ep_name
      end
      if ev_data && !ev_data.empty?
        episode_season = ev_data[0]
        episode_episode = ev_data[1]
      end
      is_episode = true
      if position
        return [name[0..position], episode_name, episode_season.to_i, episode_episode.to_i, is_episode]
      end
    end


    def extract_title(title)
      title_category = nil
      title_year = nil
      episode_name = nil
      episode_season = nil
      episode_episode = nil

      title, episode_name, episode_season, episode_episode, is_episode = extract_episode(title)

      title = title.gsub(/ \((VG|TV|V)\)$/) do |match|
        title_category = $1
        match = ""
      end
      title = title.gsub(/ \((\?\?\?\?)\)$/) do |match|
        title_year = $1
        match = ""
      end
      if !title_year
        title = title.gsub(/ \((\d\d\d\d)(|\/[IVX]+)\)$/) do |match|
          title_year = $1
          match = ""
        end
      end
      return {
        "title" => title,
        "episode_name" => episode_name,
        "episode_season" => episode_season,
        "episode_episode" => episode_episode,
        "is_episode" => is_episode,
        "title_category" => title_category,
        "title_year" => title_year
      }
    end

    def initialize(importer, filenames)
      @imp = importer
      @movie_file = filenames[0]
      @ratings_file = filenames[1]
      @completeness_file ||= {}
      @completeness_file["cast"] = filenames[2]
      @completeness_file["crew"] = filenames[3]
      @aka_file = filenames[4]
      @year_file = filenames[5]
      @release_dates_file = filenames[6]
      @running_times_file = filenames[7]
      @color_infos_file = filenames[8]
      @certificates_file = filenames[9]
      @technicals_file = filenames[10]
      @years = {}
      load_years
      import
      import_episode_relations
      @imp.xxclear_data("episode_parent_title")
      import_ratings
      import_completeness("cast")
      import_completeness("crew")
      import_akas
      import_release_dates
      import_running_times
      import_color_infos
      import_certificates
      import_technicals
    end

    def load_years
      File.open(@year_file, "r:utf-8").each_line do |line|
        line.chomp!
        data = Hash[YEAR_COLUMNS.zip(line.split(/\t/))]
        data.to_int!(["id", "movie_id"])
        @years[data["movie_id"]] ||= []
        @years[data["movie_id"]] << data["year"]
      end
    end

    def import
      File.open(@movie_file, "r:utf-8").each_line do |line|
        line.chomp!
        data = Hash[COLUMNS.zip(line.split(/\t/))]
        data.to_int!(["id", "episode_season", "episode_episode"])
        data.to_bool!(["year_open_end", "is_episode"])
        data["title_category"] = "M" if !data["title_category"]
        data["category_award_value"] = CATEGORY_AWARD_VALUE[data["title_category"]]
        data.remove_blanks!
        title_norm = data["title_norm"]

        episode_name_norm = data["episode_name_norm"]
        @imp.xxstore_data("movie_title", data["id"], data["title_norm"])
        @imp.xxstore_data("movie_episode_name", data["id"], data["episode_name_norm"])
        data.remove!(["suspended", "title_norm", "episode_name_norm", "episode_parent_title"])
        node = data["id"]
        @imp.xxstore_data("episode_parent_title", data["full_title"], node) unless data["is_episode"]
        @imp.xxstore_data("movie_is_episode", data["id"], data["is_episode"])
        @imp.xxstore_data("movie_is_tvseries", data["id"], data["title_category"] == "TVS")

        if @years[data["id"]]
          data["years"] = @years[data["id"]].map do |year|
            year == "Unknown" ? nil : year.to_i
          end.compact
        end

        data["title"] = title_norm
        data["episode_name"] = episode_name_norm
        @imp.solr_doc_start("movie", data["id"])
        @imp.solr_add("movie", data["id"], data)
      end
    end

    def import_episode_relations
      File.open(@movie_file, "r:utf-8").each_line do |line|
        line.chomp!
        data = Hash[COLUMNS.zip(line.split(/\t/))]
        data.to_int!(["id", "episode_season", "episode_episode"])
        data.to_bool!(["year_open_end", "is_episode"])
        parent_node = @imp.xxfetch_data("episode_parent_title", data["episode_parent_title"])
        episode_node = data["id"]
        next if parent_node.to_i == 0 || episode_node.to_i == 0
        @imp.xxstore_data("movie_episode_parent_node", data["id"], parent_node)
        @imp.xxstore_data("has_episodes", parent_node, true)
      end
    end

    def import_ratings
      File.open(@ratings_file, "r:utf-8").each_line do |line|
        line.chomp!
        data = Hash[RATING_COLUMNS.zip(line.split(/\t/))]
        data.to_int!(["id", "movie_id", "votes"])
        data.to_float!(["rating"])
        movie_node = data["movie_id"]
        data.remove!(["id", "movie_id"])
        @imp.solr_add("movie", movie_node, data)
      end
    end

    def import_akas
      File.open(@aka_file, "r:utf-8").each_line do |line|
        line.chomp!
        data = Hash[AKA_COLUMNS.zip(line.split(/\t/))]
        data.to_int!(["id", "movie_id"])
        movie_node = data["movie_id"]
        data.remove!(["id", "movie_id", "title_norm"])
        data["full_title"] = data["title"]
        data = data.merge(extract_title(data["full_title"]))
        data.rename_keys!({
            "full_title" => "alternate_full_title",
            "title" => "alternate_title",
            "episode_name" => "alternate_episode_name",
            "episode_season" => "alternate_episode_season",
            "episode_episode" => "alternate_episode_episode",
            "title_year" => "alternate_title_year",
            "title_category" => "alternate_title_category"
          })
        data.remove!(["is_episode"])
        data["alternate_title"] = data["alternate_title"].norm
        data["alternate_episode_name"] = data["alternate_episode_name"].norm
        @imp.solr_add("movie", movie_node, data)
      end
    end

    def import_completeness(type)
      File.open(@completeness_file[type], "r:utf-8").each_line do |line|
        line.chomp!
        data = Hash[COMPLETENESS_COLUMNS.zip(line.split(/\t/))]
        data.to_int!(["id", "movie_id", "complete_id"])
        movie_node = data["movie_id"]
        new_data = {}
        if data["complete_id"] == 1
          new_data["#{type}_complete"] = true
        elsif data["complete_id"] == 2
          new_data["#{type}_complete"] = true
          new_data["#{type}_verified"] = true
        end
        @imp.solr_add("movie", movie_node, new_data)
      end
    end

    def import_release_dates
      File.open(@release_dates_file, "r:utf-8").each_line do |line|
        line.chomp!
        data = Hash[RELEASE_DATE_COLUMNS.zip(line.split(/\t/))]
        data.to_int!(["id", "movie_id"])
        movie_node = data["movie_id"]
        data.remove!(["id", "movie_id"])
        data["release_stamp"] = Date.parse(data["release_stamp"]).strftime("%FT%TZ") if data["release_stamp"] && !data["release_stamp"].empty?
        data.remove_blanks!
        @imp.solr_add("movie", movie_node, data)
      end
    end

    def import_running_times
      File.open(@running_times_file, "r:utf-8").each_line do |line|
        line.chomp!
        data = Hash[RUNNING_TIME_COLUMNS.zip(line.split(/\t/))]
        data.to_int!(["id", "movie_id"])
        movie_node = data["movie_id"]
        data.remove!(["id", "movie_id"])
        @imp.solr_add("movie", movie_node, data)
      end
    end

    def import_color_infos
      File.open(@color_infos_file, "r:utf-8").each_line do |line|
        line.chomp!
        data = Hash[COLOR_INFO_COLUMNS.zip(line.split(/\t/))]
        data.to_int!(["id", "movie_id"])
        movie_node = data["movie_id"]
        data.remove!(["id", "movie_id"])
        @imp.solr_add("movie", movie_node, data)
      end
    end

    def import_certificates
      File.open(@certificates_file, "r:utf-8").each_line do |line|
        line.chomp!
        data = Hash[CERTIFICATE_COLUMNS.zip(line.split(/\t/))]
        data.to_int!(["id", "movie_id"])
        movie_node = data["movie_id"]
        data.remove!(["id", "movie_id"])
        @imp.solr_add("movie", movie_node, data)
      end
    end

    def import_technicals
      File.open(@technicals_file, "r:utf-8").each_line do |line|
        line.chomp!
        data = Hash[TECHNICAL_COLUMNS.zip(line.split(/\t/))]
        data.to_int!(["id", "movie_id"])
        movie_node = data["movie_id"]
        data.remove!(["id", "movie_id"])
        @imp.solr_add("movie", movie_node, data)
      end
    end
  end
end
