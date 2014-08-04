module MailyHerald
  class Subscription < ActiveRecord::Base
    belongs_to  :entity,        :polymorphic => true
    belongs_to  :list,          :class_name => "MailyHerald::List"

    validates   :entity,        :presence => true
    validates   :token,         :presence => true, :uniqueness => true

    scope       :for_entity,    lambda {|entity| where(:entity_id => entity.id, :entity_type => entity.class.base_class) }

    serialize   :data,          Hash
    serialize   :settings,      Hash

    after_initialize do
      if self.new_record?
        self.token = MailyHerald::Utils.random_hex(20)
      end
    end

    after_create :create_schedules

    def active?
      !new_record? && read_attribute(:active)
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

    def to_liquid
      #TODO fix the host
      {
        "token_url" => MailyHerald::Engine.routes.url_helpers.token_url(:token => self.token, :host => HOST)
      }
    end

    def create_schedules
      PeriodicalMailing.where(:list_id => self.list).each do |m|
        m.set_schedule_for self.entity
      end
      Sequence.where(:list_id => self.list).each do |s|
        s.set_schedule_for self.entity
      end
    end
  end
end
