class User < ApplicationRecord
  scope :active, lambda { where(active: true) }
  scope :inactive, lambda { where(active: false) }
end
