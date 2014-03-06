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
      comment_json[:elements] = comment.elements
      comment_json[:version] = comment.version
      comment_json[:tag_name] = comment.tag_name
      comment_json[:id] = comment.id
      comment_json[:type] = comment.type
      comment_json[:order_id] = comment.order_id
      comment_json[:purpose] = comment.purpose
      comment_json[:published] = comment.published
      comment_json[:updated_at] = comment.updated_at

      if comment.user_id == coord_user_id
        coordinator_theme_comments.push(comment_json)
      else
        theme_comments.push(comment_json)
      end
    end

    table_comments = []
    conversation.table_comments.each do|comment|
      comment_json = {}
      comment_json[:table_number] = comment.author.last_name
      comment_json[:name] = "Table #{comment.author.last_name}"
      comment_json[:parent_theme_ids] = comment.parent_targets.map(&:parent_id)
      comment_json[:pro_votes] = comment.pro_con_vote.try{|v| v.pro_votes} || 0
      comment_json[:con_votes] = comment.pro_con_vote.try{|v| v.con_votes} || 0
      comment_json[:editable_by_user] = (defined?(current_user).nil? || current_user.nil?) ? false : comment.editable_by_user?(current_user)
      #comment_json[:editable_by_user] = true
      comment_json[:text] = comment.text
      comment_json[:elements] = comment.elements
      comment_json[:version] = comment.version
      comment_json[:id] = comment.id
      comment_json[:type] = comment.type
      comment_json[:order_id] = comment.order_id
      comment_json[:purpose] = comment.purpose
      comment_json[:updated_at] = comment.updated_at
      table_comments.push(comment_json)
    end

    {
        title: conversation.title,
        code: conversation.code,
        privacy: conversation.privacy,
        table_comments: table_comments,
        coordinator_theme_comments: coordinator_theme_comments,
        theme_comments: theme_comments,
        role: Ability.abilities(params["current_user"], 'Conversation', conversation.id),
        details: conversation.details,
        current_timestamp: Time.new.to_i,
        theme_map: conversation.agenda.details['theme_map']
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
    if params["conversation_code"].match(/-/)
      agenda_code, data_set_code = params["conversation_code"].match(/^(\w+)-(.*)$/).captures
      agenda = Agenda.find_by(code: agenda_code)
      data_set_details = agenda.details["data_sets"][data_set_code]
      title = data_set_details["data_set_title"]
      agenda_details = agenda.details
      link_details = {}

      # check if there are any parameters that need to be evaluated for their interpolated variables
      data_set_details["parameters"].each_pair do |key,value|
        Rails.logger.debug "value for eval: #{value}"
        data_set_details["parameters"][key] = eval( '"' + value + '"') if value.class.to_s == 'String' && value.match(/#/)
      end
      coord_user_id = data_set_details["parameters"]["coordinator_user_id"].to_i
      conversation_ids = data_set_details["parameters"]["conversation_ids"].scan(/\d+/).map(&:to_i)
      top_themes_count = data_set_details["parameters"]["top_themes_count"]
      randomized_theme_ids = data_set_details["parameters"]["randomized_theme_ids"]
      if randomized_theme_ids.class != Array
        randomized_theme_ids = []
      end
      themes = ThemeAllocation.collect_top_themes_from_conversations(coord_user_id, conversation_ids, top_themes_count)
      # randomize themes, if needed
      # get the ids for the key theme comments from the conversations
      all_ids = ThemeComment.where(conversation_id: conversation_ids, user_id: coord_user_id).pluck(:id)
      # re-shuffle if the random_ids don't match the collected ids
      if randomized_theme_ids.sort != all_ids.sort
        themes.shuffle!
        randomized_theme_ids = themes.map{|t| t[:theme_id]}
        # create new hash to force active record to do the update
        new_details = {}
        new_details.merge!(agenda.details)
        new_details["data_sets"][data_set_code]["parameters"]["randomized_theme_ids"] = randomized_theme_ids
        # In a transaction clear and then add the details to force active record to do the update
        ActiveRecord::Base.transaction do
          agenda.update_attribute(:details, {} )
          agenda.update_attribute(:details, new_details )
        end
      end

      ltr = 'A'
      order_ctr = 1
      theme_comments = []
      randomized_theme_ids.each do |id|
        theme = themes.detect{|t| t[:theme_id] == id}
        theme_comments.push( {id: theme[:theme_id], order_id: order_ctr, letter: ltr, text: theme[:text]} )
        ltr = ltr.succ
        order_ctr += 1
      end

    else
      conversation = Conversation.includes(:title_comment).find_by(code: params["conversation_code"])
      themes = conversation.theme_comments.where(user_id: params["coordinator_user_id"], published: true).order(:order_id)
      title = conversation.title

      ltr = 'A'
      theme_comments = []
      themes.each do |theme|
        theme_comments.push( {id: theme.id, order_id: theme.order_id, letter: ltr, text: theme.text, published: theme.published } )
        ltr = ltr.succ
      end
    end
    {title: title, themes: theme_comments}
  end


  private
  def assign_defaults
    self.menu_roles = ['coordinator', 'participant_report', 'reporter']
  end

end