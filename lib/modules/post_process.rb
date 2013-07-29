module Modules
  module PostProcess
    extend ActiveSupport::Concern

    included do
      before_create { @_is_new_record = true }
      after_save :post_process
    end

    def post_process
      Rails.logger.debug "do post_process"
      send_to_firebase
      record_replies_and_mentions
      check_immediate_notifications
      add_to_activity_feed

      #AdminMailer.delay.follow_us("PostProcess1A-#{Time.now}@ce.org")
      #sleep 10
      #AdminMailer.delay.follow_us("PostProcess2A-#{Time.now}@ce.org")
    end
    handle_asynchronously :post_process, :priority => 20, :run_at => Proc.new { 10.seconds.from_now }

    def add_to_activity_feed
      Rails.logger.debug " I need to implement add_to_activity_feed"
    end

    def check_immediate_notifications
      Rails.logger.debug " I need to implement check_immediate_notifications"
      # any requests for this conversation with immediate_all
      requests = self.conversation.notification_requests.includes(:user).where(immediate_all: true)
      requests.each do |request|
        Rails.logger.debug "Email post to #{request.user.email}"
        ConversationMailer.delay.immediate_notification(request.user, self, "mcode", "host")
      end

    end

    def record_replies_and_mentions
      Rails.logger.debug " I need to implement record_replies_and_mentions"
    end

    def send_to_firebase
      conversation_code ||= self.conversation.try{|con| con.code} || nil
      if conversation_code
        action = @_is_new_record ? "create" : destroyed? ? "delete" : "update"
        Firebase.base_uri = "https://civicevolution.firebaseio.com/conversations/#{conversation_code}/updates/"
        Firebase.push '', self.as_json_for_firebase( action )
      end
    end

    # override as_json_for_firebase in the model as needed
    def as_json_for_firebase( action = "create" )
      data = as_json root: false, except: [:user_id]
      { class: self.class.to_s, action: action, data: data, updated_at: Time.now.getutc, source: "RoR-Firebase" }
    end

    #def send_ratings_update_to_firebase
    #  Firebase.base_uri = "https://civicevolution.firebaseio.com/conversations/#{self.conversation.code}/updates/"
    #  data = { type: type, id: id, ratings_cache: ratings_cache, number_of_votes: ratings_cache.inject{|sum,x| sum + x } }
    #  Firebase.push '', { class: 'RatingsCache', action: 'update_ratings', data: data, updated_at: Time.now.getutc, source: "RoR-Firebase" }
    #end

  end
end