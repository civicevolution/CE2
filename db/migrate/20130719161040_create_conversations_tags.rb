class CreateConversationsTags < ActiveRecord::Migration
  def change
    create_table :conversations_tags do |t|
      t.belongs_to :conversation
      t.belongs_to :tag

      t.integer :published, default: true
    end
  end
end
