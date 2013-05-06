# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :question do
    issue_id 1
    user_id 1
    text "question text"
    version 1
    status "open"
    purpose "question purpose"
  end
end
