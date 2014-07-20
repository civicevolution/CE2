class CreateTagsTable < ActiveRecord::Migration
  def change
    create_table :tags do |t|
      t.string :text

      t.timestamps
    end

    add_index :tags, :text,  :unique => true

  end
end
