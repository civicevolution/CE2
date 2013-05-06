class CreateQuestions < ActiveRecord::Migration
  def change
    create_table :questions do |t|
      t.integer :issue_id, null: false
      t.integer :user_id, null: false
      t.text :text, null: false
      t.integer :version, default: 1
      t.string :status, null: false, default: 'open'
      t.string :purpose

      t.timestamps
    end
  end
end
