# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :ui_label, :class => 'UiLabel' do
    tag "MyString"
    language "MyString"
    text "MyString"
  end
end
