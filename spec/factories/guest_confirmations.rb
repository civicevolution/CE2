# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :guest_confirmation do
    email "MyString"
    first_name "MyString"
    last_name "MyString"
    code "MyString"
    conversation_id 1
  end
end
