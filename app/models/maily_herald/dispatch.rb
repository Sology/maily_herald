module MailyHerald
  class Dispatch < ActiveRecord::Base
    validates   :name,          :presence => true, :format => {:with => /^\w+$/}, :uniqueness => true
  end
end
