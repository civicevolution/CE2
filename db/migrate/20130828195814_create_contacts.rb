class CreateContacts < ActiveRecord::Migration
  def change
    create_table :contacts do |t|
      t.integer :user_id
      t.string :first_name
      t.string :last_name
      t.string :email
      t.text :text
      t.string :reference_type
      t.string :reference_id
      t.hstore :action

      t.timestamps
    end
  end
end
