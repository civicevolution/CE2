class ThemeSmallGroupDeliberation < AgendaComponent
  after_initialize :assign_defaults, if: 'new_record?'

  attr_accessor :conversation, :table_comments, :theme_comments, :parked_comments

  def data(params, current_user)
    "return data for ThemeSmallGroupDeliberation"
    # get the data based on the inputs

    self.conversation = Conversation.includes(:title_comment).find_by(id: self.input[ "conversation_id" ])
    self.table_comments = self.conversation.table_comments.where(user_id: self.input[ "user_ids" ])
    self.theme_comments = self.conversation.theme_comments
    #self.parked_comments = self.conversation.parked_comments
    self
  end

  def self.data_theme_small_groups_page_data(params)
    current_user = params["current_user"]
    group_user_ids = params["group_user_ids"].scan(/\d+/).map(&:to_i)
    conversation = Conversation.includes(:title_comment).find_by(code: params["conversation_code"])
    table_comments = []
    conversation.table_comments.where(user_id: group_user_ids ).each do|comment|
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
    theme_comments = []
    conversation.theme_comments.each do|comment|
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
      theme_comments.push(comment_json)
    end
    #self.parked_comments = self.conversation.parked_comments
    {
      title: conversation.title,
      code: conversation.code,
      privacy: conversation.privacy,
      table_comments: table_comments,
      theme_comments: theme_comments,
      role: Ability.abilities(params["current_user"], 'Conversation', conversation.id),
      current_timestamp: Time.new.to_i
    }
  end

  def menu_details(role,email)
    begin
      name_id = self.descriptive_name.match(/Team (\d+):/).try{|m| m[1]} || ''
      if name_id != ''
        email_id = email.match(/themer-(\d+)/).try{|m| m[1] } || ''
        return nil if email_id != '' && email_id != name_id
      end
    rescue
    end
    details = {
        type: self.class.to_s,
        descriptive_name: self.descriptive_name,
        code: self.code,
        starts_at: self.starts_at,
        ends_at: self.ends_at,
        menu_template: 'theme-allocation'
    }
    conversation = Conversation.includes(:title_comment).find_by(id: self.input[ "conversation_id" ])
    details[:links] =  [ {
        title: conversation.title,
        munged_title: conversation.title.gsub(/\s/, "-").gsub(/[^\w&-]/,'').downcase[0..50],
        conversation_code: conversation.code,
        href: "/#/cmp/#{self.code}/sgd_theme/#{conversation.munged_title}"
      }
    ]
    details
  end

  private
  def assign_defaults
    self.menu_roles = ['themer']
  end

end