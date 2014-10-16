class User < ActiveRecord::Base
  scope :active, lambda { where(active: true) }
  scope :inactive, lambda { where(active: false) }
end
