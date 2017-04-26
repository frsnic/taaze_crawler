# == Schema Information
#
# Table name: books
#
#  id          :integer          not null, primary key
#  is_disabled :boolean          default(FALSE)
#  name        :string
#  isbn        :string
#  rate        :float
#  quantity    :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  taaze_link  :string
#  author      :string
#  press       :string
#  status      :string
#  annotate    :string
#  publish_at  :date
#

class Book < ActiveRecord::Base
  paginates_per 20

  scope :enabled,  -> { where(is_disabled: false) }
  scope :disabled, -> { where(is_disabled: true) }

  class << self
    require 'open-uri'

    def correction
      Book.update_details Book.enabled.where(isbn: nil), 'taaze'
      Book.update_details Book.enabled.where(rate: nil).where.not(isbn: nil).where.not(isbn: ''), 'anobii'
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
    self.isbn = ''
    page.css('.prodInfo p').each do |e|
      next unless e.text
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
      result = Typhoeus.get(URI.escape(result['href']), followlocation: true)
      page   = Nokogiri::HTML result.body
      self.update(rate: result.code == 200 ? page.xpath('//span[@class="rating"]').first.content.to_f : -1)
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
