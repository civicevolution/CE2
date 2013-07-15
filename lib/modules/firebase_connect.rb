module Modules
  module FirebaseConnect
    extend ActiveSupport::Concern

    included do
      before_create { @_is_new_record = true }
      after_save :send_to_firebase
      after_destroy :send_to_firebase
    end


    # TODO I want to override Firebase.push so it automatically adds a timestamp
    # Right now I need to make sure I add the timestamp: updated_at: Time.now.getutc
    def send_to_firebase
      action = @_is_new_record ? "create" : destroyed? ? "delete" : "update"
      Firebase.base_uri = "https://civicevolution.firebaseio.com/conversations/#{conversation_code}/updates/"
      Firebase.push '', self.as_json_for_firebase( action )
    end

    # override as_json_for_firebase in the model as needed
    def as_json_for_firebase( action = "create" )
      data = as_json root: false, except: [:user_id]
      { class: self.class.to_s, action: action, data: data, updated_at: Time.now.getutc, source: "RoR-Firebase" }
    end

    def send_ratings_update_to_firebase
      Firebase.base_uri = "https://civicevolution.firebaseio.com/conversations/#{self.conversation.code}/updates/"
      data = { type: type, id: id, ratings_cache: ratings_cache, number_of_votes: ratings_cache.inject{|sum,x| sum + x } }
      Firebase.push '', { class: 'RatingsCache', action: 'update_ratings', data: data, updated_at: Time.now.getutc, source: "RoR-Firebase" }
    end

  end

end