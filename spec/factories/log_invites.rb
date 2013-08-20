# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :log_invite do
    sender_user_id 1
    first_name "MyString"
    last_name "MyString"
    email "MyString"
    text "MyText"
    code "MyString"
    conversation_id 1
    options ""
    user_id 1
    invited_at "2013-08-19 09:39:21"
  end
end
