require 'rubygems'
require 'nokogiri'
require 'open-uri'
require 'json'
require "awesome_print"

module Crawler
  class Taaze
    attr_accessor :query_hash

    def initialize
      @query_hash = {
        cp: 1,    # page number
        ps: 1200, # page count
        ct: 0,    # all category
        cl: 1
      }
    end

    def taaze_url
      "https://www.taaze.tw/gift_index.html"
    end

    def anobii_url
      "http://www.anobii.com/search"
    end

    def to_query(hash, namespace = nil)
      hash.collect { |key, value| "#{key}=#{value}" }.compact.sort! * '&'
    end

    def generate_title_hash
      title_array = []
      while 1
        page = Nokogiri::HTML open("#{taaze_url}?#{to_query query_hash}")
        puts "== page #{query_hash[:cp]} =="
        elements = page.css("p .taazeLink")
        elements.each do |e|
          key = query_hash[:cp]
          title_array << e.text
          # insert db
          Book.find_or_create_by(name: e.text, taaze_link: e.attributes["href"].value)
        end
        break if elements.size != query_hash[:ps]
        query_hash[:cp] += 1
      end
      return title_array
    end

  end
end
