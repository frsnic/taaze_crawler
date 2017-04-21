class AddDetailToBooks < ActiveRecord::Migration
  def change
    add_column :books, :author,      :string, after: :name
    add_column :books, :press,       :string, after: :author
    add_column :books, :status,      :string, after: :press
    add_column :books, :annotate,    :string, after: :status
    add_column :books, :publish_at,  :date,   after: :annotate
  end
end
