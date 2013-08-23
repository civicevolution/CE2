# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :log_guest_confirmation do
    user_id 1
    conversation_id 1
    posted_at "2013-08-22 00:53:16"
    details ""
  end
end
