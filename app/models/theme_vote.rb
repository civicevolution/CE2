class ThemeVote < ActiveRecord::Base

  attr_accessible :group_id,  :voter_id, :theme_id

end
