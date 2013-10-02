class SmallGroupDeliberation < AgendaComponent

  attr_accessor :conversations_list, :conversation

  def data(conv_code)
    # get the data for the conversations specified in component.input
    # and load the full data for the first conversation

    # set conversations_list
    # self.input["conversations_list_ids"]
    #self.conversations_list = Conversation.where(id: self.input[ "conversations_list_ids" ])
    self.conversations_list = Conversation.includes(:title_comment).where(id: self.input[ "conversations_list_ids" ])

    # set conversation
    self.conversation = self.conversations_list.detect{|c| c.code == conv_code}

    self
  end

end