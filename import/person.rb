module Importer
  class Person
    COLUMNS = ["id", "full_name", "first_name", "last_name", "name_count", "name_norm"]
    REL_COLUMNS = ["id", "person_id", "movie_id", "role_id", "character", "sort_value", "extras",
      "occupation_score", "episode_count", "collected", "character_norm"]
    AKA_COLUMNS = ["id", "person_id", "name", "sort_value", "name_norm"]
    METADATA_COLUMNS = ["id", "person_id", "code", "value", "sort_value", "author", "metadata_value_norm"]
    CLASS="Person"
    AKA_CLASS="PersonAka"
    REL_CLASS="Occupation"
    METADATA_CLASS="PersonMetadata"
    METADATA_REL_CLASS="PersonPersonMetadata"
    ROLES={
      1 => "actor",
      2 => "actress",
      3 => "cinematographer",
      4 => "composer",
      5 => "costume-designer",
      6 => "director",
      7 => "editor",
      8 => "miscellaneous",
      9 => "producer",
      10 => "production-designer",
      11 => "writer",
      12 => "biography"
    }

    MD={
      "DB" => "date_of_birth",
      "DD" => "date_of_death",
      "HT" => "height",
      "RN" => "birth_name",
      "BG" => "biography",
      "SP" => "spouse",
      "BT" => "biographical_movies",
      "NK" => "nickname",
      "TM" => "trade_mark",
      "WN" => "where_are_they_now",
      "SA" => "salary",
      "BO" => "biography_print",
      "PI" => "portrayed_in",
      "QU" => "personal_quotes",
      "PT" => "pictorial",
      "TR" => "trivia",
      "IT" => "interview",
      "OW" => "other_works",
      "AT" => "article",
      "CV" => "cover_photo",
    }

    PERSON_MD=["DB", "DD", "HT", "RN"]

    def initialize(importer, filenames)
      @imp = importer
      @node_file = filenames[0]
      @aka_file = filenames[1]
      @relation_file = filenames[2]
      @metadata_file = filenames[3]
      import_nodes
      import_akas
      import_relations
      import_metadata
      @imp.xxclear_data("movie_title")
      @imp.xxclear_data("movie_episode_name")
      @imp.xxclear_data("person_name")
    end

    def import_nodes
      File.open(@node_file, "r:utf-8").each_line do |line|
        line.chomp!
        data = Hash[COLUMNS.zip(line.split(/\t/))]
        data.to_int!(["id"])
        data.remove_blanks!
        name_norm = data["name_norm"]
        @imp.xxstore_data("person_name", data["id"], data["name_norm"])
        data.remove!(["name_norm"])
        node = data["id"]
        data["name"] = name_norm
        @imp.solr_doc_start("person", node)
        @imp.solr_add("person", node, data)
      end
    end

    def import_akas
      File.open(@aka_file, "r:utf-8").each_line do |line|
        line.chomp!
        data = Hash[AKA_COLUMNS.zip(line.split(/\t/))]
        data.to_int!(["id", "person_id"])
        data.copy_to_int!({"sort_value" => "sort_integer"})
        person_node = data["person_id"]
        data.remove!(["id", "person_id", "name_norm"])
        data.rename_keys!({"name" => "alternate_name"})
        @imp.solr_add("person", person_node, data)
      end
    end

    def import_relations
      person_movie_count = {}
      person_score = {}
      movie_score = {}
      person_link_score = {}
      person_movie_episode_count = {}
      person_movie_episode_character = {}
      person_movie_episode_sort_value = {}
      File.open(@relation_file, "r:utf-8").each_line do |line|
        line.chomp!
        data = Hash[REL_COLUMNS.zip(line.split(/\t/))]
        data.to_int!(["id", "person_id", "movie_id", "episode_count", "role_id"])
        data.copy_to_int!({"sort_value" => "sort_integer"})
        data.remove_blanks!
        data.remove!(["character_norm"])
        movie_node = data["movie_id"]
        person_node = data["person_id"]
        data["role"] = ROLES[data["role_id"]]

        parent_node = @imp.xxfetch_data("movie_episode_parent_node", data["movie_id"])
        if parent_node && @imp.xxfetch_data("movie_is_tvseries", data["movie_id"]) &&
            @imp.xxfetch_data("movie_is_episode", data["movie_id"]) &&
            @imp.xxfetch_data("has_episodes", parent_node) &&
            [1,2].include?(data["role_id"])
          pid = data["person_id"]
          person_movie_episode_count[parent_node] ||= {}
          person_movie_episode_count[parent_node][pid] ||= []
          person_movie_episode_count[parent_node][pid] << {
            :character => data["character"],
            :sort_value => data["sort_integer"],
            :role_id => data["role_id"],
            :role => data["role"]
          }
          movie_score[parent_node] ||= 0
          movie_score[parent_node] += data["occupation_score"].to_i
        end

        movie_score[movie_node] ||= 0
        movie_score[movie_node] += data["occupation_score"].to_i
        person_name = @imp.xxfetch_data("person_name", data["person_id"])
        solr_data = data.get(["character"])
        solr_data["cast"] = person_name
        solr_data["cast_ids"] = data["person_id"].to_i
        @imp.solr_add("movie", movie_node, solr_data)

        person_score[person_node] ||= 0
        person_score[person_node] += data["occupation_score"].to_i
        person_link_score[person_node] ||= 0
        person_link_score[person_node] += @imp.xxfetch_data("movie_score", movie_node).to_i
        person_movie_count[person_node] ||= 0
        person_movie_count[person_node] += 1
        movie_title = @imp.xxfetch_data("movie_title", data["movie_id"])
        movie_episode_name = @imp.xxfetch_data("movie_episode_name", data["movie_id"])
        solr_data = data.get(["character"])
        solr_data["movies"] = [movie_title, movie_episode_name].compact.join(" ")
        @imp.solr_add("person", person_node, solr_data)
      end
      person_score.keys.each do |key|
        @imp.solr_add("person", key, {"occupation_score" => person_score[key]})
      end
      person_movie_count.keys.each do |key|
        @imp.solr_add("person", key, {"movie_count" => person_movie_count[key]})
      end
      person_link_score.keys.each do |key|
        @imp.solr_add("person", key, {"link_score" => person_link_score[key]})
      end
      movie_score.keys.each do |key|
        score = movie_score[key]
        if person_movie_episode_count[key]
          score = 1000*(score / sum_episode_counts(person_movie_episode_count[key].keys.map {|x| person_movie_episode_count[key][x].count }).to_f)
        end
        @imp.solr_add("movie", key, {"occupation_score" => score.to_i })
      end
      person_movie_episode_count.keys.each do |movie_node|
        highest_episode_count = 0
        person_movie_episode_count[movie_node].keys.sort_by do |person_id|
          episode_count = person_movie_episode_count[movie_node][person_id].count
          highest_episode_count = episode_count if episode_count > highest_episode_count
          sort_value = person_movie_episode_count[movie_node][person_id].map {|x| x[:sort_value] || 2**32 }.min
          [-episode_count, sort_value]
        end.each_with_index do |person_id,idx|
          episode_count = person_movie_episode_count[movie_node][person_id].count
          next if episode_count < 10 && (episode_count < highest_episode_count*0.5)
          next if episode_count < highest_episode_count*0.05
          person_node = person_id
          person_name = @imp.xxfetch_data("person_name", person_id)
          episode_character = find_max_char(person_movie_episode_count[movie_node][person_id].map {|x| x[:character] })
          role = person_movie_episode_count[movie_node][person_id].first[:role]
          role_id = person_movie_episode_count[movie_node][person_id].first[:role_id]
          extras = episode_count == 1 ? "(1 episode)" : "(#{episode_count} episodes)"
          data = {
            "character" => episode_character,
            "extras" => extras,
            "role" => role,
            "role_id" => role_id,
            "episode_count" => episode_count,
            "sort_integer" => idx+1,
            "sort_value" => (idx+1).to_s,
            "collected" => true
          }
          solr_data = {
            "character" => episode_character,
            "cast" => person_name,
            "cast_ids" => person_id,
          }
          @imp.solr_add("movie", movie_node, solr_data)
        end
      end
    end

    def sum_episode_counts(list)
      list.inject(0) { |r,a| r+a }
    end

    def find_max_char(charlist)
      character = charlist.group_by {|x| x}
      max_char_cnt = 0
      max_char = nil
      character.keys.each do |char|
        if character[char].size > max_char_cnt
          max_char = char
          max_char_cnt = character[char].size
        end
      end
      max_char
    end

    def import_metadata
      File.open(@metadata_file, "r:utf-8").each_line do |line|
        line.chomp!
        data = Hash[METADATA_COLUMNS.zip(line.split(/\t/))]
        data.to_int!(["id", "person_id"])
        data.copy_to_int!({"sort_value" => "sort_integer"})
        data.remove_blanks!
        person_node = data["person_id"]
        if PERSON_MD.include?(data["code"]) && data["value"]
          @imp.solr_add("person", person_node, {MD[data["code"]] => data["value"]})
        else
          query_data = data.get(["metadata_value_norm"])
          data.remove!(["person_id", "metadata_value_norm"])
          data.rename_keys!({"value" => "metadata_value"})
          data["key"] = MD[data["code"]]
          data[data["key"]] = data["metadata_value"]
          query_data[data["key"]] = query_data["metadata_value_norm"]
          query_data.remove!(["metadata_value_norm"])
          @imp.solr_add("person", person_node, query_data)
        end
      end
    end
  end
end
