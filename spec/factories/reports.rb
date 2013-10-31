# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :report do
    title "MyString"
    source_type "MyString"
    source_code "MyString"
    layout "MyString"
    version 1
    header "MyString"
    settings ""
  end
end
