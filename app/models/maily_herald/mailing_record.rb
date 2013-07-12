module MailyHerald
  class MailingRecord < ActiveRecord::Base
		belongs_to :entity, :polymorphic => true
		belongs_to :mailing, :polymorphic => true
  end
end
