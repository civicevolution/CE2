class CreateEndorsements < ActiveRecord::Migration
  def change
    create_table :endorsements do |t|
      t.integer :issue_id
      t.integer :user_id
      t.text :text

      t.timestamps
    end
  end
end
