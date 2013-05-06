# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :issue do
    initiative_id 1
    user_id 1
    title "My issue title: punctuated"
    description "issue description"
    version 1
    status "open"
    purpose "issue purpose"
  end
end
