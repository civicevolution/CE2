class TableComment < Comment

  def active_model_serializer
    TableCommentSerializer
  end

  attr_accessor :auto_tag_disabled

  belongs_to :conversation

  before_validation :set_order_id_for_new_table_comment

  #validates :pro_votes, numericality: { only_integer: true, greater_than_or_equal_to: 0, message: 'Must enter a number for members in favor' }
  #validates :con_votes, numericality: { only_integer: true, greater_than_or_equal_to: 0, message: 'Must enter a number for members opposed' }

  #after_create  :record_pro_con_votes
  #after_update  :update_pro_con_votes, unless: :post_process_disabled

  after_save :tag_to_purpose_theme, unless: :auto_tag_disabled

  def tag_to_purpose_theme
    if self.purpose == 'table'
      return
    end
    @old_purpose = self.purpose_was
    coordinator_user_id = self.conversation.agenda.details['coordinator_user_id']
    theme_com = ThemeComment.where(purpose: self.purpose, conversation_id: self.conversation_id, user_id: coordinator_user_id ).first_or_create do |theme|
      theme.text = "Auto-generated theme for tag: #{self.purpose}"
      theme.status = 'auto-tag-theme'
      theme.tag_name = self.purpose
    end
    if @old_purpose.nil?
      new_theme_id = theme_com.id
      old_theme_id = 0
    elsif @old_purpose != self.purpose
      new_theme_id = theme_com.id
      old_theme = ThemeComment.where(purpose: @old_purpose, conversation_id: self.conversation_id, user_id: coordinator_user_id ).try{|coms| coms[0]}
      old_theme_id = old_theme ? old_theme.id : 0
      old_theme.child_comments.delete(self) unless old_theme.nil?
    else
      return
    end
    theme_com.child_comments << self
    message = {action: "update", class: "AutoTaggedTableComment", updated_at: Time.now, source: "TC-RT-Notification",
      data: { table_comment_id: self.id, old_theme_id: old_theme_id, new_theme_id: new_theme_id }
    }
    channel = "/#{self.conversation.code}"
    Modules::FayeRedis::publish(message,channel)
  end

  def record_pro_con_votes
    self.create_pro_con_vote pro_votes: self.pro_votes, con_votes: self.con_votes
  end

  def update_pro_con_votes
    if self.pro_con_vote
      self.pro_con_vote.update_columns({ pro_votes: self.pro_votes, con_votes: self.con_votes})
    else
      self.create_pro_con_vote pro_votes: self.pro_votes, con_votes: self.con_votes
    end
  end

  def set_order_id_for_new_table_comment
    # set order_id to the max order_id +1 for this conversation, starting at 1
    return true unless self.order_id.nil?
    self.order_id = TableComment.where(conversation_id: self.conversation_id).maximum(:order_id).try{ |max| max + 1 } || 1
  end


  validate :check_tag_ids
  after_save :update_tag_ids

  def check_tag_ids
    if !tag_ids || tag_ids.size == 0
      errors.add(:tag_ids, "Comment must have at least one tag")
      return false
    end
  end

  def update_tag_ids
    #Rails.logger.debug "check if tag_ids defined"
    if !tag_ids.nil?
      #Rails.logger.debug "process the tag_ids to make sure it is up-to-date"
      CommentTagAssignment.updateCommentTagAssignments(self)
    end
  end


end