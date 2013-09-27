# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :agenda_role do
    agenda_id 1
    name "MyString"
    identifier 1
    access_code "MyString"
  end
end
