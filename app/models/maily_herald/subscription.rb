module MailyHerald
  class Subscription < ActiveRecord::Base
    belongs_to  :entity,        :polymorphic => true

    validates   :entity,        :presence => true
    validates   :token,         :presence => true, :uniqueness => true
    validate    :aggregate_presence

    scope       :for_entity,    lambda {|entity| where(:entity_id => entity.id, :entity_type => entity.class.base_class) }

    serialize   :data,          Hash
    serialize   :settings,      Hash

    after_initialize do
      if self.new_record?
        self.token = MailyHerald::Utils.random_hex(20)
      end
    end

    def active?
      if aggregated?
        aggregate.active?
      else
        !new_record? && read_attribute(:active)
      end
    end

    def deactivate!
      aggregated? ? aggregate.deactivate! : update_attribute(:active, false)
      save!
    end

    def activate!
      aggregated? ? aggregate.activate! : update_attribute(:active, true)
      save!
    end

    def toggle!
      active? ? deactivate! : activate!
    end

    def to_liquid
      #TODO fix the host
      {
        "token_url" => MailyHerald::Engine.routes.url_helpers.token_url(:token => self.token, :host => HOST)
      }
    end

    private

    def aggregate_presence
      self.errors.add(:base, "aggregate not present") if aggregated? && !aggregate
    end
  end
end
