# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :invite do
    sender_user_id 1
    first_name "MyString"
    last_name "MyString"
    email "MyString"
    text "MyText"
    code "MyString"
    conversation_id 1
    options ""
  end
end
