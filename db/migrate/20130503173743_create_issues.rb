class CreateIssues < ActiveRecord::Migration
  def change
    create_table :issues do |t|
      t.integer :initiative_id, null: false
      t.integer :user_id, null: false
      t.string :title, null: false
      t.text :description, null: false
      t.integer :version, default: 1
      t.string :status, null: false, default: 'open'
      t.string :purpose

      t.timestamps
    end
  end
end
