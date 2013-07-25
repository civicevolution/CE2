# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :notification_request do
    conversation_id 1
    user_id 1
    immediate_me false
    immediate_all false
    send_daily true
  end
end
