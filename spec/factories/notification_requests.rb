# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :notification_request do
    conversation_id 1
    user_id 1
    immediate_me false
    immediate_all false
    send_at "2013-07-23 14:34:08"
  end
end
