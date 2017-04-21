class AddTaazeLinkToBooks < ActiveRecord::Migration
  def change
    add_column :books, :taaze_link, :string, after: :quantity
  end
end
