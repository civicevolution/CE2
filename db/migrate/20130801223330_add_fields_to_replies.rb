class AddFieldsToReplies < ActiveRecord::Migration
  def change
    add_column :replies, :version, :integer
    add_column :replies, :quote, :boolean
    add_column :replies, :author, :string
    add_column :replies, :code, :string
  end
end
