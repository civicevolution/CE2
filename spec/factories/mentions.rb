# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :mention do
    comment_id 1
    version 1
    user_id 1
    mentioned_user_id 1
  end
end
