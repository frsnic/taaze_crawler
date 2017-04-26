class AddIsDisabledToBooks < ActiveRecord::Migration
  def change
    add_column :books, :is_disabled, :boolean, after: :id, default: false
  end
end
