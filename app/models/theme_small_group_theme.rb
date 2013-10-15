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

  def menu_details(role,email)
    details = {
        type: self.class.to_s,
        descriptive_name: self.descriptive_name,
        code: self.code,
        starts_at: self.starts_at,
        ends_at: self.ends_at,
        menu_template: 'theme-allocation'
    }
    conversation = Conversation.includes(:title_comment).find_by(id: self.input[ "conversation_id" ])
    details[:links] =  []
    details[:links].push(
      {
        title: "Theme: #{conversation.title}",
        href: "/#/cmp/#{self.code}/themes_theme/#{conversation.munged_title}"
      }
    ) if role == 'coordinator'
    details[:links].push(
     {
         title: "Display themes: #{conversation.title}",
         href: "/#/cmp/#{self.code}/theme-results/#{conversation.munged_title}"
     }
    )  if ['coordinator', 'reporter'].include?(role)
    details
  end

  def results(params=nil, current_user=nil)
    self.conversation = Conversation.includes(:title_comment).find_by(id: self.input[ "conversation_id" ])

    self.theme_comments = self.conversation.theme_comments.where(user_id: self.input[ "coordinator_user_id" ]).order(:order_id)

    self
  end

  def participant_report_details

    self.results()

    ltr = 'A'
    theme_comments = []
    self.theme_comments.each do |theme|
      theme_comments.push( {id: id, letter: ltr, text: theme.text}
      )
      ltr = ltr.succ
    end

    {
      klass: self.class.to_s,
      title: self.conversation.title,
      theme_comments: theme_comments
    }
  end

  def report_data

    self.results()

    ltr = 'A'
    theme_comments = []
    self.theme_comments.each do |theme|
      theme_comments.push( {id: id, letter: ltr, text: theme.text}
      )
      ltr = ltr.succ
    end
    theme_comments
  end

  private
  def assign_defaults
    self.menu_roles = ['coordinator', 'participant_report', 'reporter']
  end

end