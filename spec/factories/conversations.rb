# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :conversation do
    question_id 1
    status "open"
  end
end
