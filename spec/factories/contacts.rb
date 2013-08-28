# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :contact do
    user_id 1
    first_name "MyString"
    last_name "MyString"
    text "MyText"
    reference_type "MyString"
    reference_id 1
  end
end
