class SmallGroupDeliberation < AgendaComponent
  after_initialize :assign_defaults, if: 'new_record?'

  attr_accessor :conversations_list, :conversation

  def data(params, current_user)
    conv_code = params[:conv_code]
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

  def self.data_small_group_deliberation_page_data(params)
    current_user = params["current_user"]
    agenda_details = params["agenda_details"]

    conversation = Conversation.includes(:title_comment).find_by(code: params["conversation_code"])

    conversations_list_ids = []
    begin
      conversations_list_ids = agenda_details["conversation_ids"].detect{|a| a.include?(conversation.id) } || []
    rescue
    end
      conversations_list = Conversation.includes(:title_comment).where(id: conversations_list_ids)

    links = agenda_details["links"]["group"].values

    conversations = []
    conversations_list.each do |conversation|
      # I need the link codes to make full links
      link = links.detect{|l| l["conversation_code"] == conversation.code}
      conversations.push(
        {
          agenda_code: agenda_details["code"],
          link_code: link["link_code"],
          code: conversation.code,
          title: conversation.title,
          munged_title: conversation.munged_title
        }
      )
    end

    table_comments = []
    conversation.table_comments.where(user_id: current_user.id ).each do|comment|
      comment_json = {}
      comment_json[:table_number] = comment.author.last_name
      comment_json[:name] = "Table #{comment.author.last_name}"
      comment_json[:parent_theme_ids] = comment.parent_targets.map(&:parent_id)
      comment_json[:pro_votes] = comment.pro_con_vote.try{|v| v.pro_votes} || 0
      comment_json[:con_votes] = comment.pro_con_vote.try{|v| v.con_votes} || 0
      comment_json[:editable_by_user] = (defined?(current_user).nil? || current_user.nil?) ? false : comment.editable_by_user?(current_user)
      comment_json[:text] = comment.text
      comment_json[:version] = comment.version
      comment_json[:id] = comment.id
      comment_json[:type] = comment.type
      comment_json[:order_id] = comment.order_id
      comment_json[:updated_at] = comment.updated_at
      table_comments.push(comment_json)
    end

    {
      title: conversation.title,
      code: conversation.code,
      privacy: conversation.privacy,
      table_comments: table_comments,
      role: Ability.abilities(params["current_user"], 'Conversation', conversation.id),
      current_timestamp: Time.new.to_i,
      conversations_list: conversations
    }
  end


  def menu_details(role,email)
    details = {
      type: self.class.to_s,
      descriptive_name: self.descriptive_name,
      code: self.code,
      starts_at: self.starts_at,
      ends_at: self.ends_at,
      menu_template: 'small-group-deliberation',
      conversations: []
    }
    self.conversations_list = Conversation.includes(:title_comment).where(id: self.input[ "conversations_list_ids" ])
    self.conversations_list.each do |conversation|
      details[:conversations].push( {
                                      title: conversation.title,
                                      munged_title: conversation.title.gsub(/\s/, "-").gsub(/[^\w&-]/,'').downcase[0..50],
                                      conversation_code: conversation.code,
                                      link: "/#/cmp/#{self.code}/sgd/#{conversation.code}/#{conversation.munged_title}"
                                    }
      )
    end
    details
  end

  private
  def assign_defaults
    self.menu_roles = ['group']
  end

end