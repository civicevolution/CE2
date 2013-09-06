class ConversationGroupPresenter

  def initialize( conversation, current_user, table_id )

    @conversation = conversation

    current_user_id = current_user.try{ |user| user.id} || nil

    @conversation.table_comments.where(user_id: current_user_id)


=begin
    comment_ids = @conversation.comments.map(&:id)
    my_ratings = Rating.where( user_id: current_user_id, ratable_id: comment_ids, ratable_type: 'Comment').inject({}){|hash, r| hash[r.ratable_id] = r.rating ; hash }
    my_bookmarks = Bookmark.where( user_id: current_user_id, target_id: comment_ids, target_type: 'Comment').inject({}){|hash, b| hash[b.target_id] = true ; hash }
    @conversation.comments.each do |com|
      com.my_rating = my_ratings[com.id]
      com.bookmark = my_bookmarks[com.id]
    end

    # everyone who can access this conversation can read the updates from Firebase
    firebase_auth_data = { conversations_read: { "#{@conversation.code}" => true } }

    # only authenticated users can read their user channel or potentially write to the conversation channel on firebase
    if current_user_id
      firebase_auth_data['userid'] = "#{current_user_id}"
      firebase_auth_data['conversations_write'] = { "#{@conversation.code}" => true }
    end

    @conversation.firebase_token = Firebase::FirebaseTokenGenerator.new(Firebase.auth).create_token(firebase_auth_data)
    #Rails.logger.debug "ConversationPresenter is initialized"
=end

  end

  def conversation
    @conversation
  end


end