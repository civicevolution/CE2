class AddTagNameAndTagArrayToComments < ActiveRecord::Migration
  def change
    remove_column :comments, :references, :string
    add_column :comments, :tag_name, :string
    add_column :comments, :tags, :string, array: true
  end
end
