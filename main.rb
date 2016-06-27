require 'rubygems'
require 'nokogiri'
require 'open-uri'
require 'json'
require "awesome_print"

class TaazeCrawler

  attr_accessor :query_hash, :title_hash, :rates_hash

  def initialize
    @query_hash = {
      cp: 1,    # page number
      ps: 1200, # page count
      ct: 0,    # all category
      cl: 1
    }
    @title_hash = File.exist?(title_json_file_name) ? JSON.parse(File.read(title_json_file_name)) : generate_title_hash()
    @rates_hash = File.exist?(rates_json_file_name) ? JSON.parse(File.read(rates_json_file_name)) : { "rates" => [] }
  end

  def taaze_url
    "http://www.taaze.tw/gift_index.html"
  end

  def anobii_url
    "http://www.anobii.com/search"
  end

  def title_json_file_name
    "title_hash.json"
  end

  def rates_json_file_name
    "rate.json"
  end

  def to_query(hash, namespace = nil)
    hash.collect { |key, value| "#{key}=#{value}" }.compact.sort! * '&'
  end

  def generate_title_hash
    title_hash = {}
    while 1
      page = Nokogiri::HTML open("#{taaze_url}?#{to_query query_hash}")
      puts "== page #{query_hash[:cp]} =="
      titles = page.css("p .taazeLink")
      titles.each do |e|
        key = query_hash[:cp]
        title_hash[key] = [] unless title_hash.has_key? key
        title_hash[key] << e.children.first.content
      end

      File.open(title_json_file_name, 'w') { |f| f.write(title_hash.to_json) } and break if titles.size != query_hash[:ps]
      query_hash[:cp] += 1
    end
  end

  def taaze_search(title)
    title_hash.each do |key, value|
      if value.find { |e| /#{title}/ =~ e }
        query_hash[:cp] = key
        puts "== Find in #{taaze_url}?#{to_query query_hash} =="
      end
    end
  end

  def anobii_search(keyword)
    return if rates_hash["rates"].select { |h| h["title"] == keyword }.size > 0
    page = Nokogiri::HTML open(URI.escape "#{anobii_url}?keyword=#{keyword}").read, nil, 'utf-8'
    result = page.xpath('//li[@class="title"]/a').first
    if result
      link = result['href']
      page = Nokogiri::HTML open(URI.escape link)
      result = page.xpath('//span[@itemprop="isbn"]').first
      isbn = result ? result.content : nil
      rates_hash["rates"] << {
        title: keyword,
        rate:  page.xpath('//span[@class="rating"]').first.content.to_f,
        isbn:  isbn
      }

      File.open(rates_json_file_name, 'w') { |f| f.write(rates_hash.to_json) }
    end
  end

  def better_rates
    rates_hash
  end

end

taaze_crawler = TaazeCrawler.new
# taaze_crawler.taaze_search ARGV[0] || "戀愛"
uniq_title = taaze_crawler.title_hash.values.flatten.compact.uniq
# ap taaze_crawler.title_hash.values.flatten.compact.uniq[0..40]
uniq_title.each_with_index do |title, index|
  begin
    puts "== #{title} #{(((index + 1) / uniq_title.size.to_f) * 100).to_i}% =="
    taaze_crawler.anobii_search title
  rescue Exception => e
    puts e
  end
end
