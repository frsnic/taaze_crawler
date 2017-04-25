# == Schema Information
#
# Table name: books
#
#  id         :integer          not null, primary key
#  quantity   :integer
#  rate       :float
#  name       :string
#  isbn       :string
#  taaze_link :string
#  author     :string
#  press      :string
#  status     :string
#  annotate   :string
#  publish_at :date
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Book < ActiveRecord::Base
  paginates_per 20

  class << self
    require 'open-uri'

    def correction
      Book.update_details Book.where(isbn: nil), 'taaze'
      Book.update_details Book.where(rate: nil).where.not(isbn: nil).where.not(isbn: ''), 'anobii'
    end

    def update_details(books, type, sec = 3)
      arr = []
      books.each_slice(books.size > 1 ? books.size / 1 : 1) do |elements|
        arr << Thread.new {
          elements.each { |book| book.taaze_detail;  sleep(sec)     } if type == 'taaze'
          elements.each { |book| book.anobii_detail; sleep(sec) } if type == 'anobii'
        }
      end
      arr.each { |e| e.join }
    end
  end

  def taaze_detail
    return unless self.taaze_link
    puts "#{self.id} #{self.taaze_url}"
    page = Nokogiri::HTML open(self.taaze_url)
    page.css('.prodInfo p').each do |e|
      next unless e.text
      self.isbn        = ''
      self.author      = e.text.gsub('作者：', '') if e.text.include? '作者：'
      self.press       = e.text.gsub('出版社：', '') if e.text.include? '出版社：'
      self.isbn        = e.text.gsub('ISBN/ISSN：', '') if e.text.include? 'ISBN/ISSN：'
      self.status      = e.text.gsub('書況：', '') if e.text.include? '書況：'
      self.annotate    = e.text.gsub('備註：無畫線註記', '') if e.text.include? '備註：'
      self.publish_at  = e.text.gsub('出版日期：', '') if e.text.include? '出版日期：'
    end
    self.save
  end

  def anobii_detail
    return unless self.isbn
    puts "#{self.id} #{self.anobii_url}"
    page = Nokogiri::HTML open(URI.escape self.anobii_url).read, nil, 'utf-8'
    result = page.xpath('//li[@class="title"]/a').first
    if result
      search_uri = URI.parse(URI.escape result['href'])
      result = Net::HTTP.get_response(search_uri)
      if %w(301 302).include? result.code
        uri = URI.parse result.header['location']
        unless uri.host
          search_uri.path = result.header['location']
          uri = search_uri.host 
        end
        result = Net::HTTP.get_response(uri.host, uri.path) 
      end
      page = Nokogiri::HTML result
      self.update(rate: page.xpath('//span[@class="rating"]').first.content.to_f)
    else
      self.update(rate: -1)
    end
  rescue => e
    Rails.logger.info "== #{e.message} #{e.backtrace} =="
  end

  def taaze_url
    "https://www.taaze.tw#{self.taaze_link}"
  end

  def anobii_url
    "http://www.anobii.com/search?keyword=#{self.isbn}"
  end

end
