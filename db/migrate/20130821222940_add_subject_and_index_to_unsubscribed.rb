class AddSubjectAndIndexToUnsubscribed < ActiveRecord::Migration
  def change
    add_column :unsubscribes, :subject, :string
    add_index :unsubscribes, :email, unique: true
  end
end
