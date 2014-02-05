class AddJsonToComments < ActiveRecord::Migration
  class Comment < ActiveRecord::Base
  end

  def change
    add_column :comments, :elements, :json
    Comment.reset_column_information
    reversible do |dir|
      dir.up { Comment.all.each{|com| com.post_process_disabled = true; com.update_attribute(:elements, { text: com.text }) }  }
    end
  end

end
