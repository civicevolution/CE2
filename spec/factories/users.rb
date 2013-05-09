# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  sequence :email do |n|
    "person#{n}@example.com"
  end
end

FactoryGirl.define do
  factory :user do
    name 'Test User'
    first_name 'Test'
    last_name 'User'
    email { generate(:email) }
    password 'changeme'
    password_confirmation 'changeme'
    # required if the Devise Confirmable module is used
    confirmed_at Time.now
  end
end
