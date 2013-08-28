# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :activity_report do
    action "MyString"
    user_id 1
    conversation_id 1
    ip_address ""
    details ""
  end
end
