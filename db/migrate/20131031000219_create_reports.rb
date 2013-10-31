class CreateReports < ActiveRecord::Migration
  def change
    create_table :reports do |t|
      t.integer :user_id
      t.string :agenda_code
      t.string :title
      t.string :source_type
      t.string :source_code
      t.string :layout
      t.integer :version, default: 1
      t.string :header
      t.hstore :settings
      #t.has_attached_file :image

      t.timestamps
    end
  end
end
