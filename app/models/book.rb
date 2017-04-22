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

  default_scope { order('rate DESC') }

  class << self
    require 'open-uri'

    def taaze_detail(books)
      arr = []
      books.each_slice(books.size > 2 ? books.size / 2 : 1) do |elements|
        arr << Thread.new {
          elements.each do |book|
            page = Nokogiri::HTML open("https://www.taaze.tw#{book.taaze_link}")
            page.css('.prodInfo p').each do |e|
              next unless e.text
              book.author      = e.text.gsub('作者：', '') if e.text.include? '作者：'
              book.press       = e.text.gsub('出版社：', '') if e.text.include? '出版社：'
              book.isbn        = e.text.gsub('ISBN/ISSN：', '') if e.text.include? 'ISBN/ISSN：'
              book.status      = e.text.gsub('書況：', '') if e.text.include? '書況：'
              book.annotate    = e.text.gsub('備註：無畫線註記', '') if e.text.include? '備註：'
              book.publish_at  = e.text.gsub('出版日期：', '') if e.text.include? '出版日期：'
            end
            book.save
          end
        }
      end
      arr.each { |e| e.join }
    end

  end

end
