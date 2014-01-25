class ConversationPresenter

  def initialize( conversation, current_user, session_id, display_mode )
    #Rails.logger.debug "ConversationPresenter is started"
    @conversation = conversation
    @conversation.display_mode = display_mode

    #Rails.logger.debug "ConversationPresenter with display_mode #{@conversation.display_mode}"

    current_user_id = current_user.try{ |user| user.id} || nil

    comment_ids = @conversation.comments.map(&:id)
    my_ratings = Rating.where( user_id: current_user_id, ratable_id: comment_ids, ratable_type: 'Comment').inject({}){|hash, r| hash[r.ratable_id] = r.rating ; hash }
    my_bookmarks = Bookmark.where( user_id: current_user_id, target_id: comment_ids, target_type: 'Comment').inject({}){|hash, b| hash[b.target_id] = true ; hash }
    @conversation.comments.each do |com|
      com.my_rating = my_ratings[com.id]
      com.bookmark = my_bookmarks[com.id]
    end

    @conversation.session_id = session_id
    Rails.logger.debug "XXXX Create a CSRF token for Faye"

  end

  def conversation
    @conversation
  end


end