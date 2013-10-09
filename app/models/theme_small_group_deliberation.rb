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

  def menu_details(role,email)
    begin
      name_id = self.descriptive_name.match(/(\d+)$/).try{|m| m[1]} || ''
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