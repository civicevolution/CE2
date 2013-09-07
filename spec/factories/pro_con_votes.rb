# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :pro_con_vote do
    comment_id 1
    pro_votes 1
    con_votes 1
  end
end
