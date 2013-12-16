# encoding: UTF-8
require 'unicode_utils'

class Hash
  def append_hash!(hash, sumfields = [])
    hash.keys.each do |key|
      if sumfields.include?(key)
        self[key] ||= 0
        self[key] += hash[key].to_i
      elsif self[key].is_a?(Array)
        self[key] << hash[key] if !hash[key].nil? && !(key == "class" && !self["class"].nil?)
        self[key].flatten!
        self[key].compact!
        self[key].uniq!
      else
        self[key] = [self[key], hash[key]].flatten.compact.uniq if !hash[key].nil? && !(key == "class" && !self["class"].nil?)
      end
    end
  end

  def to_int!(columns)
    columns.each do |col|
      self[col] = self[col].to_i unless self[col].nil? || self[col].empty?
    end
  end

  def to_float!(columns)
    columns.each do |col|
      self[col] = self[col].to_f unless self[col].nil? || self[col].empty?
    end
  end

  def to_bool!(columns)
    columns.each do |col|
      self[col] = self[col] == "true" ? true : false unless self[col].nil? || self[col].empty?
    end
  end

  def copy_to_int!(hash)
    hash.each do |k,v|
      self[v] = self[k].to_i unless self[k].nil? || self[k].empty?
    end
  end

  def replace_nil!(hash)
    hash.each do |k,v|
      self[k] = v if self[k].nil? || self[k].empty?
    end
  end

  def rename_keys!(hash)
    hash.each do |k,v|
      self[v] = self[k] if self.has_key?(k)
      self.delete(k)
    end
  end

  def remove_blanks!
    self.delete_if {|k,v| v.nil? || (v.is_a?(String) && v.empty?)}
  end

  def remove!(columns)
    self.delete_if {|k,v| columns.include?(k) }
  end

  def get(key_list)
    self.select {|k,v| key_list.include?(k) }
  end

  def to_xml(file, section, node)
    self.keys.each { |key| self[key].to_xml(file, key, section, node) }
  end
end

class NilClass
  def to_xml(file, key, section, node)
  end

  def norm
    nil
  end
end

class FalseClass
  def to_xml(file, key, section, node)
    file.puts "#{section}_#{node}:<field name=\"#{key}\">false</field>"
  end
end

class TrueClass
  def to_xml(file, key, section, node)
    file.puts "#{section}_#{node}:<field name=\"#{key}\">true</field>"
  end
end

class Fixnum
  def to_xml(file, key, section, node)
    file.puts "#{section}_#{node}:<field name=\"#{key}\">#{self.to_s}</field>"
  end
end

class Float
  def to_xml(file, key, section, node)
    file.puts "#{section}_#{node}:<field name=\"#{key}\">#{self.to_s}</field>"
  end
end

class String
  def to_xml(file, key, section, node)
    file.puts "#{section}_#{node}:<field name=\"#{key}\"><![CDATA[#{self}]]></field>"
  end

  def norm
    decomposed = UnicodeUtils.nfkd(self).gsub(/[^\u0000-\u00ff]/, "")
    UnicodeUtils.downcase(decomposed)
  end
end

class Array
  def to_xml(file, key, section, node)
    self.each { |item| item.to_xml(file, key, section, node) }
  end
end
