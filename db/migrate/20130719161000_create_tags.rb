class CreateTags < ActiveRecord::Migration
  def change
    create_table :tags do |t|
      t.string :name, null: false
      t.boolean :published, default: true
      t.integer :user_id
      t.integer :admin_user_id

      t.timestamps
    end
  end
end
