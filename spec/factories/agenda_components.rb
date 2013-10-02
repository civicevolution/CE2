# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :agenda_component do
    agenda_id 1
    code "MyString"
    descriptive_name "MyString"
    type ""
    input ""
    output ""
    status "MyString"
    starts_at "2013-09-29 23:08:09"
    ends_at "2013-09-29 23:08:09"
  end
end
