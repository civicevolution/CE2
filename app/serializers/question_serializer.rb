class QuestionSerializer < ActiveModel::Serializer
  self.root = false

  attributes :id, :text, :status, :version, :purpose

  has_many :conversations

  # only let the user see conversations he belongs to and/or are public
  def conversations
    object.conversations #.where(:created_by => current_user)
    # #object.conversations.where("id > 100000")
  end

end
