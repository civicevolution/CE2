class AgendaRole < ActiveRecord::Base
  attr_accessible :agenda_id, :name, :identifier, :access_code
  belongs_to :agenda

end
