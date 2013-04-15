class AddAuthenticableToUsers < ActiveRecord::Migration
  # Note: You can't use change, as User.update_all with fail in the down migration
  def up
    ## Token authenticatable
    add_column :users, :authentication_token, :string
    add_index :users, :authentication_token, :unique => true
  end

  def down
    remove_column :users, :authentication_token
  end
end