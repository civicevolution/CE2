# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :tag do
    name "MyString"
    published false
    user_id 1
    admin_user_id 1
  end
end
