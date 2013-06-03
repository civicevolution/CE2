module Modules
  module FirebaseConnect
    extend ActiveSupport::Concern

    included do
      before_create { @_is_new_record = true }
      after_save :send_to_firebase
      after_destroy :send_to_firebase
    end


    def send_to_firebase
      return if @_cancel_firebase_send
      action = @_is_new_record ? "create" : destroyed? ? "delete" : "update"
      Firebase.base_uri = "https://civicevolution.firebaseio.com/issues/#{conversation.question.issue_id}/conversations/#{conversation_id}/updates/"
      Firebase.push '', self.as_json_for_firebase( action )
    end

    # override as_json_for_firebase in the model as needed
    def as_json_for_firebase( action = "create" )
      data = as_json root: false, except: [:user_id]
      { class: self.class.to_s, action: action, data: data, source: "RoR-Firebase" }
    end
  end
end