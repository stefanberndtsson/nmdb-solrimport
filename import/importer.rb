include Java
require 'jvyaml'
require 'time'
require 'date'
require 'pp'
require 'fileutils'

module Importer
  class Import
    SOLR_URL = "http://localhost:8080/solr/core0"
    SOLR_FAST = false

    def initialize
      @solr_doc = {}
      @solr_filename = "temp/solr"
      @solr_files = {}
      @solr_dir_created = {}
      STDERR.puts("DEBUG: initialize()")
      @index = {}
      @store = {}
      @counter = {}
    end

    def solr_dir(node)
      (node/10000).to_s
    end

    def solr_file(section, node)
      dir = "#{section}_#{solr_dir(node)}"
      return @solr_files[dir] if @solr_files[dir]
      FileUtils.mkdir_p("#{@solr_filename}/#{dir}")
      @solr_files[dir] = File.open("#{@solr_filename}/#{dir}/output.xml", "w:utf-8")
    end

    def solr_write(section, node, data)
      data.to_xml(solr_file(section, node), section, node)
    end

    def solr_doc_start(section, node)
      solr_file(section, node).write("#{section}_#{node}:<doc>\n")
    end

    def solr_add(section, node, data, sumfields = [])
      return if !node
      data.delete("class") unless ["Movie", "Person"].include?(data["class"])
      if data["id"]
        data["nmdb_id"] = data["id"]
        data["class"] = section
        data["id"] = "#{section}:#{data["id"]}"
      end
      solr_write(section, node, data)
    end

    def xxdetach_data
      @store.keys.each do |key|
        STDERR.puts("DEBUG: Clearing #{key}")
        clear_data(key)
      end
    end

    def xxstore_data(key, identifier, data, mode = :replace)
      @store[key] ||= {}
      if mode == :append
        if @store[key][identifier].is_a?(Array)
          @store[key][identifier] << data
        else
          @store[key][identifier] = [@store[key][identifier], data].compact
        end
      elsif mode == :replace
        @store[key][identifier] = data
      end
    end

    def xxfetch_data(key, identifier)
      @store[key] ||= {}
      @store[key][identifier]
    end

    def xxclear_data(key)
      @store.delete(key)
    end

    def xxstored_identifiers(key)
      @store[key].keys
    end

    def xxdecode_links(node_class, text)
      return if !text
      text.scan(/@@(PID|MID)@(\d+)@@/).each do |list|
        link_type,link_id = list
        link_node = nil
        if link_type == "MID"
          link_node = fetch_data("movie_id", link_id.to_i)
        elsif link_type == "PID"
          link_node = fetch_data("person_id", link_id.to_i)
        end
      end
    end
  end
end
