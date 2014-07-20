class CreateCommentTagAssignments < ActiveRecord::Migration
  def change
    create_table :comment_tag_assignments do |t|
      t.integer :tag_id
      t.integer :comment_id
      t.integer :conversation_id
      t.integer :user_id
      t.boolean :star

      t.timestamps
    end

    add_index :comment_tag_assignments, [:tag_id, :comment_id, :user_id], :unique => true,
      :name => 'index_comment_tag_assignments_on_tag_comment_and_user_id'

  end
end
