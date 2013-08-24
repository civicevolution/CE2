# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :autosafe, :class => 'Autosave' do
    id 1
    code "MyString"
    data ""
  end
end
