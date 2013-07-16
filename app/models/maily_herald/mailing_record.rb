module MailyHerald
  class MailingRecord < ActiveRecord::Base
    belongs_to  :entity,        :polymorphic => true
    belongs_to  :mailing,       :polymorphic => true

    validates   :entity,        :presence => true
    validates   :mailing,       :presence => true
    validates   :token,         :presence => true
  end
end
