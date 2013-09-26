class ParkedComment < ActiveRecord::Base
  attr_accessible :conversation_id, :user_id, :parked_ids
end
