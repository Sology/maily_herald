FactoryGirl.define do
  factory :user do
    sequence(:name)  {|n| "John #{n}"}
    sequence(:email)  {|n| "john#{n}@doe.com"}
    active true

    factory :inactive_user do
      active false
    end
  end
end
