module MailyHerald
  class Subscription < ActiveRecord::Base
    belongs_to  :entity,        polymorphic: true
    belongs_to  :list,          class_name: "MailyHerald::List"

    validates   :entity,        presence: true
    validates   :list,          presence: true
    validates   :token,         presence: true, uniqueness: true
    validate do
      self.errors.add(:entity, :wrong_type) if self.entity_type != self.list.context.model.base_class.to_s
    end

    scope       :for_entity,    lambda {|entity| where(entity_id: entity.id, entity_type: entity.class.base_class.to_s) }
    scope       :active,        lambda { where(active: true) }
    scope       :for_model,     lambda {|model| joins("JOIN #{model.table_name} ON #{model.table_name}.id = #{Subscription.table_name}.entity_id AND #{Subscription.table_name}.entity_type = '#{model.base_class.to_s}'") }

    serialize   :data,          Hash
    serialize   :settings,      Hash

    after_initialize do
      if self.new_record?
        self.token = MailyHerald::Utils.random_hex(20)
      end
    end

    after_save :update_schedules, if: Proc.new{|s| s.active_changed?}

    def self.get_from(entity)
      if entity.has_attribute?(:maily_subscription_id) && entity.maily_subscription_id
        subscription = MailyHerald::Subscription.new

        entity.attributes.each do |k, v|
          if match = k.match(/^maily_subscription_(\w+)$/)
            subscription.send("#{match[1]}=", v)
          end
        end

        subscription.readonly!
        subscription
      end
    end

    def active?
      read_attribute(:id) && read_attribute(:active)
    end

    def deactivate!
      update_attribute(:active, false)
    end

    def activate!
      update_attribute(:active, true)
    end

    def toggle!
      active? ? deactivate! : activate!
    end

    def token_url
      MailyHerald::Engine.routes.url_helpers.maily_unsubscribe_url(self)
    end

    def to_liquid
      {
        "token_url" => token_url
      }
    end

    def update_schedules
      AdHocMailing.where(list_id: self.list).each do |m|
        m.set_schedule_for self.entity
      end
      OneTimeMailing.where(list_id: self.list).each do |m|
        m.set_schedule_for self.entity
      end
      PeriodicalMailing.where(list_id: self.list).each do |m|
        m.set_schedule_for self.entity
      end
      Sequence.where(list_id: self.list).each do |s|
        s.set_schedule_for self.entity
      end
    end

    def logs
      self.list.logs.for_entity(self.entity)
    end
  end
end
