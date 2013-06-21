# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :endorsement do
    issue_id 1
    user_id 1
    text "MyText"
  end
end
