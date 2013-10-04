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

  def menu_details
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