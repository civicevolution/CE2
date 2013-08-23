class LogGuestPost < ActiveRecord::Base

  attr_accessible :post_type, :user_id, :first_name, :last_name, :email, :conversation_id, :text, :purpose, :reply_to_id,
                  :reply_to_version, :request_to_join, :reviewed_at, :review_details, :comment_id

  belongs_to :conversation

end
