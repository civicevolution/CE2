class AddNameCountToUser < ActiveRecord::Migration
  def change
    add_column :users, :name_count, :integer
  end
end
