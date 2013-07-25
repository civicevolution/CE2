class AddEmailOkToUsers < ActiveRecord::Migration
  def change
    add_column :users, :email_ok, :boolean, default: true
  end
end
