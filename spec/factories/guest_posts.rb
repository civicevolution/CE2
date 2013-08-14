# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :guest_post do
    post_type "MyString"
    user_id 1
    first_name "MyString"
    last_name "MyString"
    email "MyString"
    conversation_id 1
    text "MyText"
    purpose "MyString"
    reply_to_id 1
    reply_to_version 1
    request_to_join true
  end
end
