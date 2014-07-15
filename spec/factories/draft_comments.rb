# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :draft_comment do
    code "MyString"
    data ""
    user_id 1
  end
end
