FactoryGirl.define do
  factory :user do
    sequence(:name)  {|n| "John #{n}"}
    sequence(:email)  {|n| "john#{n}@doe.com"}
  end
end
