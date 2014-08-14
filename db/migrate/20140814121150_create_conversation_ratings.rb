class CreateConversationRatings < ActiveRecord::Migration
  def change
    create_table :conversation_ratings do |t|
      t.integer :conversation_id
      t.integer :user_id
      t.string :rating_type
      t.json :rating_data

      t.timestamps
    end

    add_index :conversation_ratings, [:conversation_id, :user_id, :rating_type], :unique => true,
              :name => 'index_conversation_ratings_on_con_type_and_user_id'

  end
end
