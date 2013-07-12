module MailyHerald
  class Mailing < ActiveRecord::Base
		attr_accessible :name, :context, :sequence, :conditions, :title, :sender, :delay, :template

		belongs_to :sequence, :class_name => "MailyHerald::Sequence"
		has_many :records, :as => :mailing, :class_name => "MailyHerald::MailingRecord"
  end
end
