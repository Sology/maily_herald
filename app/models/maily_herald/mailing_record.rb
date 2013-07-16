module MailyHerald
  class MailingRecord < ActiveRecord::Base
    belongs_to  :entity,        :polymorphic => true
    belongs_to  :mailing,       :polymorphic => true

    validates   :entity,        :presence => true
    validates   :mailing,       :presence => true
    validates   :token,         :presence => true, :uniqueness => true

    before_validation :generate_token

    def generate_token
      self.token = MailyHerald::Utils.random_hex(20) if new_record?
    end

  end
end
