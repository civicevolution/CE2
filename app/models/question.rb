class Question < ActiveRecord::Base
  attr_accessible :issue_id, :purpose, :status, :text, :user_id, :version

  belongs_to :issue
  belongs_to :user
  has_many :conversations

  validates :issue_id, :user_id, :text, :version, :status, :purpose, presence: true

end
