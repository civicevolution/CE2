# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :parked_comment do
    conversation_id 1
    user_id 1
    parked_ids 1
  end
end
