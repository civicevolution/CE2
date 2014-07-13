module Modules
  module PostProcess
    extend ActiveSupport::Concern

    included do
      before_create { @_is_new_record = true }
      after_save :post_process, unless: :post_process_disabled
      after_initialize { |com| @_published_state_at_init = com.published }
    end

    def post_process
      Rails.logger.debug "do post_process"
      record_replies
      record_mentions
      realtime_notification
      check_immediate_notifications
      notify_for_prescreen
      add_to_activity_feed

      #AdminMailer.delay.follow_us("PostProcess1A-#{Time.now}@ce.org")
      #sleep 10
      #AdminMailer.delay.follow_us("PostProcess2A-#{Time.now}@ce.org")
    end
    #handle_asynchronously :post_process, :priority => 20, :run_at => Proc.new { 10.seconds.from_now }
    handle_asynchronously :post_process

    # When do I create a record
    # comment params has in_reply_to_id and in_reply_to_version keys
    # comment text has embedded quotes
    #
    # Don't record as a reply to if the comment is sequential to its target
    #
    # reply comment is the comment being saved
    # target comment is the comment being targeted by the quote or reply to button
    #
    # Reply
    #     id:             Assigned
    #     comment_id:     id of reply comment
    #     reply_to_id:    id of the target comment from in_reply_to_id and from id in embedded quotes
    #     version:        version of the target comment
    #     quote:          true if embedded quote token, otherwise false
    #     author:         author of reply comment
    #     code:           photo code of the author of the reply comment
    #
    # Fully update the replies each time the comment is edited
    #
    # I need to save in_reply_to_id on the comment so I don't lose it the next time I edit the comment
    # newComment.in_reply_to_id, newComment.in_reply_to_version
    # Or can I just retrieve it from the replies record?
    #
    # Don't create duplicate records
    # open new records
    # remove duplicates
    # eager load the target comment(s) versions
    # add target data
    # and then save them
    #
    #'user-name="' + params[0] + '" ' +
    #'purpose="' + params[1] + '" ' +
    #'id="' + params[2] + '" ' +
    #'photo_code="' + params[3] + '" ' +
    #'version="' + params[4] + '" ' +

    # Don't record as a reply to if the comment is sequential to its target
    # maintain the reply record if this was a quote

    def record_replies
      #Rails.logger.debug "Post process record replies"

      reply_to_records = []

      # Now parse the comment text for embedded quotes

      quote_regex = /<blockquote([^>]*)>((?:[\s\S](?!<blockquote=[^>]*>))*?)<\/blockquote>/im

      self.text.scan(quote_regex).each do |match|
        attrs = {}
        match[0].scan(/(\w+)="([^"]*)"/).each do |attr|
          attrs[attr[0]] = attr[1]
        end
        reply_to_records.push Reply.new comment_id: self.id, reply_to_id: attrs['id'], version: attrs['version'], quote: true
      end

      # now remove duplicate records, but retain any record with qself.textuote = false
      reply_to_records.uniq!{|r| r[:reply_to_id]}


      if self.in_reply_to_id
        # if there is a reply record for an embedded quote, delete it before adding a reply record for a reply comment
        reply_to_records.reject!{|r| r.reply_to_id == self.in_reply_to_id }
        # do not create this reply record if the reply is ordered immediately after the target
        # I need the order_id of the target
        order_id = Comment.where(id: self.in_reply_to_id).pluck(:order_id)[0]
        if order_id != self.order_id - 1
          reply_to_records.push Reply.new comment_id: self.id, reply_to_id: self.in_reply_to_id, version: self.in_reply_to_version, quote: false
        end
      end

      if !reply_to_records.empty?
        # eager load the target_comments so I can get the author name and code
        comments = Comment.includes(:author).where( id: reply_to_records.map(&:reply_to_id) )
        reply_to_records.each do |reply|
          com = comments.detect{|c| c.id == reply.reply_to_id}
          if com
            reply.author = "#{com.author.first_name} #{com.author.last_name}"
            reply.code = com.author.code
            reply.user_id = com.user_id
          end
        end
      end

      update_replies_collection(self,reply_to_records )

    end

    # update_replies_collection

    #  reply_to_records maintain the collection of replies
    #  reply_to_records is the set for the current version of the reply comment
    #
    #  Iterate through the associated records
    #    Test each record
    #      Is quote = false?
    #        Maintain a record that has quote = false
    #        Remove matching record in reply_to_records (matching is comment_id, reply_to_id, quote)
    #      Does record exist in reply_to_records (matching is comment_id, reply_to_id, quote)
    #        Remove from reply_to_records
    #
    #    Does reply_to_records have any remaining records?
    #      Add them to the association with <<

    def update_replies_collection(comment,reply_to_records )
      #reply_to_records.each do |rec|
      #  puts "pending new rec #{rec.inspect}"
      #end

      unused_reply_records_to_destroy = []
      comment.reply_to_targets.each do |current_reply_rec|
        if current_reply_rec.quote == false
          # keep the reply rec with quote false for ever as this indicates comment started as a reply to another comment
          reply_to_records.reject!{|r| r.comment_id == current_reply_rec.comment_id && r.reply_to_id == current_reply_rec.reply_to_id && r.quote == false }
        else
          rec = reply_to_records.detect{|r| r.comment_id == current_reply_rec.comment_id && r.reply_to_id == current_reply_rec.reply_to_id }
          #puts "rec: #{rec}"
          if rec # if it is part of assoc remove from the pending list
            reply_to_records.reject!{|r| r.comment_id == current_reply_rec.comment_id && r.reply_to_id == current_reply_rec.reply_to_id }
          else # if it is part of assoc and not in the pending list, mark for removal from assoc
            #puts "Mark for removal #{current_reply_rec.inspect}"
            unused_reply_records_to_destroy.push current_reply_rec
            #current_reply_rec.comment_id = nil # mark to delete
          end
        end
      end

      unused_reply_records_to_destroy.each do |rec|
        comment.reply_to_targets.destroy(rec)
      end

      reply_to_records.each do |rec|
        #puts "add new rec to reply_to_records #{rec.inspect}"
        rec.conversation_id = comment.conversation_id
        comment.reply_to_targets << rec
      end
    end


    def record_mentions
      #Rails.logger.debug " I need to implement record_mentions"
      # parse comment text for \s\@\w+\b

      mentioned_names = self.text.scan(/(?<!\w)@\w+/).map{|n| n.sub('@','') }.uniq
      mentioned_user_ids = User.where(name: mentioned_names).pluck(:id)

      mentions = []
      mentioned_user_ids.each do |mentioned_user_id|
        mentions.push Mention.new comment_id: self.id, version: self.version, user_id: self.user_id, mentioned_user_id: mentioned_user_id
      end

      self.mentions = mentions
    end

    def realtime_notification
      conversation_code ||= self.conversation.try{|con| con.code} || nil
      Rails.logger.debug "post_process realtime_notification for conversation_code: #{conversation_code}"
      if conversation_code
        action = @_is_new_record ? "create" : destroyed? ? "delete" : "update"
        message = self.as_json_for_notification( action )
        channel = "/#{conversation_code}"
        FayeRedis::publish(message,channel)
      end
    end

    #
    # Immediate notification has two modes
    # immediate_all - user wants to be notified of every post (do not send post to its author)
    # immediate_me - user wants to be notified of every post that is a reply to their post or mentions them (do not send post to its author)
    #

    def check_immediate_notifications
      # no immediate notification on edited conversation comments (what about a new mention?)
      # unless the comment has just been published
      return if !@_is_new_record && @_published_state_at_init && self.type == 'ConversationComment'
      return if self.published == false

      #Rails.logger.debug "I need to implement check_immediate_notifications"
      # any requests for this conversation with immediate_all
      #requests = self.conversation.notification_requests.includes(:user).where(immediate_all: true)
      requests = self.conversation.notification_requests.includes(:user).where('immediate_all = true OR immediate_me = true')
      requests.each do |request|
        next if request.user_id = self.user_id # don't send notification of a comment to the author of the comment
        # if immediate_all, just send the notification
        # if immediate_me, check if the notification mentions or replies to me
        if request.immediate_me
          # check self.reply_to_targets for my user_id
          index = self.reply_to_targets.index{|r| r.user_id == request.user_id }
          if index.nil?
            # if no reply check for a mention
            # check self.mentions for my user_id as mentioned_user_id
            index = self.mentions.index{|m| m.mentioned_user_id == request.user_id }
          end
          # if no reply or mention, go on to the next request
          if index.nil?
            next
          end
        end
        # either reply or mention match for immediate_me or immediate_all - so send now
        #Rails.logger.debug "Email post to #{request.user.email}"
        ConversationMailer.delay.immediate_notification(request.user, self, "mcode")
      end
    end

    def notify_for_prescreen
      Rails.logger.debug "notify_for_prescreen - do I need to notify curators of comments that must be prescreened"
    end

    def add_to_activity_feed
      Rails.logger.debug "I need to implement add_to_activity_feed"
    end




    # override as_json_for_notification in the model as needed
    def as_json_for_notification( action = "create" )
      data = as_json root: false, except: [:user_id]
      { class: self.class.to_s, action: action, data: data, updated_at: Time.now.getutc, source: "RT-Notification" }
    end

    #def send_ratings_update_to_realtime
    #  realtime.base_uri = "https://civicevolution.realtimeio.com/conversations/#{self.conversation.code}/updates/"
    #  data = { type: type, id: id, ratings_cache: ratings_cache, number_of_votes: ratings_cache.inject{|sum,x| sum + x } }
    #  realtime.push '', { class: 'RatingsCache', action: 'update_ratings', data: data, updated_at: Time.now.getutc, source: "RoR-realtime" }
    #end

  end
end