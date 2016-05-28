require 'rubygems'
require 'nokogiri'
require 'open-uri'
require 'json'

class TaazeCrawler

  attr_accessor :query_hash, :results, :file_name

  def initialize
    @query_hash = {
      cp: 1,    # page number
      ps: 1200, # page count
      ct: 0,    # all category
      cl: 1
    }
    @results = {}
    @file_name = 'results.json'
    File.exist?(file_name) ? @results = JSON.parse(File.read(file_name)) : generate_results()
  end

  def taaze_url
    "http://www.taaze.tw/gift_index.html"
  end

  def to_query(hash, namespace = nil)
    hash.collect { |key, value| "#{key}=#{value}" }.compact.sort! * '&'
  end

  def generate_results
    while 1
      page = Nokogiri::HTML open("#{taaze_url}?#{to_query query_hash}")
      puts "== page #{query_hash[:cp]} =="
      titles = page.css("p .taazeLink")
      titles.each do |e|
        key = query_hash[:cp]
        results[key] = [] unless results.has_key? key
        results[key] << e.children.first.content
      end

      File.open(file_name, 'w') { |f| f.write(results.to_json) } and break if titles.size != query_hash[:ps]
      query_hash[:cp] += 1
      sleep 3
    end
  end

  def search(title)
    results.each do |key, value|
      if value.find { |e| /#{title}/ =~ e }
        query_hash[:cp] = key
        puts "== Find in #{taaze_url}?#{to_query query_hash} =="
      end
    end
  end

end

taaze_crawler = TaazeCrawler.new
taaze_crawler.search ARGV[0]
