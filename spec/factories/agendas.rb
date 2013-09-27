# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :agenda do
    title "MyString"
    description "MyText"
    code "MyString"
    access_code "MyString"
    template_name "MyString"
    list false
    status ""
  end
end
