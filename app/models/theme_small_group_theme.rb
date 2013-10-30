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


  def self.data_coordinator_theming_page_data(params)
    current_user = params["current_user"]
    conversation = Conversation.includes(:title_comment).find_by(code: params["conversation_code"])
    coord_user_id = params["coordinator_user_id"].to_i

    theme_comments = []
    coordinator_theme_comments = []
    conversation.theme_comments.each do |comment|
      comment_json = {}
      comment_json[:parent_theme_ids] = comment.parent_targets.map(&:parent_id).uniq
      comment_json[:ordered_child_ids] = comment.child_targets.map(&:child_id).uniq
      comment_json[:name] = "#{comment.author.first_name} #{comment.author.last_name}"
      comment_json[:editable_by_user] = ((defined? current_user).nil? || current_user.nil?) ? false : comment.editable_by_user?(current_user)
      comment_json[:text] = comment.text
      comment_json[:version] = comment.version
      comment_json[:tag_name] = comment.tag_name
      comment_json[:id] = comment.id
      comment_json[:type] = comment.type
      comment_json[:order_id] = comment.order_id
      comment_json[:updated_at] = comment.updated_at

      if comment.user_id == coord_user_id
        coordinator_theme_comments.push(comment_json)
      else
        theme_comments.push(comment_json)
      end
    end
    {
        title: conversation.title,
        code: conversation.code,
        privacy: conversation.privacy,
        table_comments: [],
        coordinator_theme_comments: coordinator_theme_comments,
        theme_comments: theme_comments,
        role: Ability.abilities(params["current_user"], 'Conversation', conversation.id),
        current_timestamp: Time.new.to_i
    }
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


  def self.data_key_themes_with_examples(params)
    conversation = Conversation.includes(:title_comment).find_by(code: params["conversation_code"])
    themes = conversation.theme_comments.where(user_id: params["coordinator_user_id"]).order(:order_id)

    ltr = 'A'
    theme_comments = []
    themes.each do |theme|
      theme_comments.push( {id: theme.id, order_id: theme.order_id, letter: ltr, text: theme.text} )
      ltr = ltr.succ
    end
    theme_comments
    {title: conversation.title, themes: theme_comments}
  end


  private
  def assign_defaults
    self.menu_roles = ['coordinator', 'participant_report', 'reporter']
  end

end