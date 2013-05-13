class CreateAttachments < ActiveRecord::Migration
  def change
    create_table :attachments do |t|
      t.integer :attachable_id, null: false
      t.string  :attachable_type, null: false
      t.integer :user_id, null: false
      t.string  :title
      t.text  :description
      t.integer :version, null: false, default: 1
      t.string :status, null: false, default: 'new'

      t.attachment :attachment

      t.timestamps
    end
  end
end
