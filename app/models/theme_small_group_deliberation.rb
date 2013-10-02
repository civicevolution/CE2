class ThemeSmallGroupDeliberation < AgendaComponent
  attr_accessor :conversation, :table_comments, :theme_comments, :parked_comments

  def data(args)
    "return data for ThemeSmallGroupDeliberation"
    # get the data based on the inputs

    self.conversation = Conversation.includes(:title_comment).find_by(id: self.input[ "conversation_id" ])
    self.table_comments = self.conversation.table_comments.where(user_id: self.input[ "user_ids" ])
    self.theme_comments = self.conversation.theme_comments
    #self.parked_comments = self.conversation.parked_comments
    self
  end

end