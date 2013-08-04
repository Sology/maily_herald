module MailyHerald
  class Subscription < ActiveRecord::Base
    belongs_to  :entity,        :polymorphic => true

    validates   :entity,        :presence => true
    validates   :token,         :presence => true, :uniqueness => true

    scope       :for_entity,    lambda {|entity| where(:entity_id => entity.id, :entity_type => entity.class.base_class) }

    serialize   :data,          Hash
    serialize   :settings,      Hash

    before_validation :generate_token

    def generate_token
      self.token = MailyHerald::Utils.random_hex(20) if new_record?
    end

    def active?
      !new_record? && read_attribute(:active)
    end
  end
end
