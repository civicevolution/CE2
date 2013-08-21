# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :log_email do
    token "MyString"
    email "MyString"
    subject "MyString"
  end
end
