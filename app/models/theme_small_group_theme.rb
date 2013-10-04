class ThemeSmallGroupTheme < AgendaComponent
  after_initialize :assign_defaults, if: 'new_record?'

  attr_accessor :conversation, :coordinator_theme_comments, :theme_comments

  def data(params, current_user)
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

  def menu_details
    details = {
        type: self.class.to_s,
        descriptive_name: self.descriptive_name,
        code: self.code,
        starts_at: self.starts_at,
        ends_at: self.ends_at,
        menu_template: 'theme-allocation'
    }
    conversation = Conversation.includes(:title_comment).find_by(id: self.input[ "conversation_id" ])
    details[:conversation] =  {
        title: conversation.title,
        munged_title: conversation.title.gsub(/\s/, "-").gsub(/[^\w&-]/,'').downcase[0..50],
        conversation_code: conversation.code,
        link: "/#/cmp/#{self.code}/themes_theme/#{conversation.munged_title}"
    }
    details
  end

  def results(params, current_user)
    self.conversation = Conversation.includes(:title_comment).find_by(id: self.input[ "conversation_id" ])

    self.theme_comments = self.conversation.theme_comments.where(user_id: self.input[ "coordinator_user_id" ]).order(:order_id)

    self
  end


  private
  def assign_defaults
    self.menu_roles = ['coordinator']
  end

end