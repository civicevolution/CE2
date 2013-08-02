class AddCodeToUsers < ActiveRecord::Migration
  def change
    add_column :users, :code, :string
    add_index :users, :code,                :unique => true
  end
end
