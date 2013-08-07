class CreateMailyHeraldTables < ActiveRecord::Migration
  def change
    create_table :maily_herald_mailings do |t|
      t.string            :type,                                        :null => false
      t.integer           :sequence_id
      t.string            :context_name
      t.text              :conditions
      t.string            :trigger,           :default => 'manual',     :null => false
      t.string            :mailer_name,       :default => 'generic',    :null => false
      t.string            :name,                                        :null => false
      t.string            :title,                                       :null => false
      t.string            :from
      t.text              :template,                                    :null => false
      t.integer           :relative_delay
      t.datetime          :start
      t.text              :start_var
      t.integer           :period
      t.boolean           :enabled,           :default => false
      t.integer           :position,          :default => 0,            :null => false
      t.boolean           :autosubscribe,     :default => true
      t.boolean           :override_subscription, :default => false,    :null => true
      t.string            :subscription_group
      t.string            :token_action,      :default => "unsubscribe",:null => false

      t.timestamps
    end
		add_index :maily_herald_mailings, :name, :unique => true
    add_index :maily_herald_mailings, :context_name
    add_index :maily_herald_mailings, :trigger

    create_table :maily_herald_sequences do |t|
      t.string            :context_name,                                :null => false
      t.string            :name,                                        :null => false
      t.datetime          :start
      t.text              :start_var
      t.boolean           :enabled,           :default => false
      t.boolean           :autosubscribe,     :default => true
      t.boolean           :override_subscription, :default => false,    :null => true
      t.string            :subscription_group
      t.string            :token_action,      :default => "unsubscribe",:null => false

      t.timestamps
    end
    add_index :maily_herald_sequences, :context_name

    create_table :maily_herald_subscriptions do |t|
      t.string            :type,                                        :null => false
      t.integer           :entity_id,                                   :null => false
      t.string            :entity_type,                                 :null => false
      t.integer           :mailing_id
      t.integer           :sequence_id
      t.string            :token,                                       :null => false
      t.text              :settings
      t.text              :data
      t.boolean           :active,             :default => true
      t.datetime          :delivered_at

      t.timestamps
    end
		add_index :maily_herald_subscriptions, [:type, :entity_id, :entity_type, :mailing_id, :sequence_id], :unique => true, :name => "index_maliy_herald_subscriptions_unique"

    create_table :maily_herald_delivery_logs do |t|
      t.datetime          :delivered_at
      t.integer           :entity_id,                                   :null => false
      t.string            :entity_type,                                 :null => false
      t.integer           :mailing_id
    end
  end
end
