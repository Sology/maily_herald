module MailyHerald
  class Sequence < ActiveRecord::Base
		has_many :records, :as => :mailing, :class_name => "MailingRecord"
  end
end
