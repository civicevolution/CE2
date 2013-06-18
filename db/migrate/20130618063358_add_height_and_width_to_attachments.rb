class AddHeightAndWidthToAttachments < ActiveRecord::Migration
  def change
    add_column :attachments, :image_height, :integer
    add_column :attachments, :image_width, :integer
  end
end
