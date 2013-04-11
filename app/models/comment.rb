class Comment < ActiveRecord::Base
  attr_accessible :liked, :name, :text
end
