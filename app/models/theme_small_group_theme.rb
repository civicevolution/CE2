class ThemeSmallGroupTheme < AgendaComponent
  attr_accessor :conversation, :coordinator_theme_comments, :theme_comments

  def data(args)
    Rails.logger.debug "return data for ThemeSmallGroupTheme"
    # get the data based on the inputs

    self.conversation = Conversation.includes(:title_comment).find_by(id: self.input[ "conversation_id" ])

    coord_user_id = self.input[ "coordinator_user_id" ]
    theme_comments = []
    coordinator_theme_comments = []
    self.conversation.theme_comments.each do |theme|
      if theme.user_id == coord_user_id
        coordinator_theme_comments.push(theme)
      else
        theme_comments.push(theme)
      end
    end

    self.coordinator_theme_comments = coordinator_theme_comments
    self.theme_comments = theme_comments

    self
  end

end