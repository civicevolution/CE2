class AddNameIndexToUsers < ActiveRecord::Migration
  def change
    add_index "users", ["name"], name: "index_users_on_name", unique: true, using: :btree
  end
end
