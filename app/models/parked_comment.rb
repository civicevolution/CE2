class ParkedComment < ActiveRecord::Base
  attr_accessible :conversation_id, :user_id, :parked_ids
  belongs_to :user, -> { select :id, :code, :first_name, :last_name, :name}

end
