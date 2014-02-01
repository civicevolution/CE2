# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :recommendation_vote do
    group_id 1
    voter_id 1
    conversation_id 1
    recommendation 1
  end
end
