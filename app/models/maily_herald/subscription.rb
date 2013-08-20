module MailyHerald
  class Subscription < ActiveRecord::Base
    belongs_to  :entity,        :polymorphic => true

    validates   :entity,        :presence => true
    validates   :token,         :presence => true, :uniqueness => true
    validate    :aggregate_presence

    scope       :for_entity,    lambda {|entity| where(:entity_id => entity.id, :entity_type => entity.class.base_class) }

    serialize   :data,          Hash
    serialize   :settings,      Hash

    before_validation :generate_token

    def generate_token
      self.token = MailyHerald::Utils.random_hex(20) if new_record?
    end

    def active?
      if aggregated?
        aggregate.active?
      else
        !new_record? && read_attribute(:active)
      end
    end

    def deactivate!
      case target.token_action
      when :unsubscribe
        update_attribute(:active, false)
      when :unsubscribe_group
        MailingSubscription.for_entity(entity).joins(:mailing).where(:maily_herald_mailings => {:subscription_group => target.subscription_group}).update_all(:active => false)
        SequenceSubscription.for_entity(entity).joins(:sequence).where(:maily_herald_sequences => {:subscription_group => target.subscription_group}).update_all(:active => false)
      end
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
