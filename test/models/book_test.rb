# == Schema Information
#
# Table name: books
#
#  id          :integer          not null, primary key
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
#  is_disabled :boolean          default(FALSE)
#

require 'test_helper'

class BookTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
