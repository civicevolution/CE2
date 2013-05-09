# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :comment do
    type 'Comment'
    user_id 1
    conversation_id 1
    text "Comment text"
    version 1
    status "new"
    order_id 1
    purpose "purpose"
    references "references"
    association :author, factory: :user
  end
end

