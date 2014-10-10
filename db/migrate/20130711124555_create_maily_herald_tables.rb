class CreateMailyHeraldTables < ActiveRecord::Migration
  def change
    create_table :maily_herald_dispatches do |t|
      t.string            :type,                                        null: false
      t.integer           :sequence_id
      t.string            :context_name
      t.text              :conditions
      t.string            :trigger
      t.string            :mailer_name
      t.string            :name,                                        null: false
      t.string            :title
      t.string            :subject
      t.string            :from
      t.text              :template
      t.integer           :absolute_delay
      t.datetime          :start
      t.text              :start_var
      t.integer           :period
      t.boolean           :enabled,           default: false
      t.boolean           :autosubscribe
      t.boolean           :override_subscription
      t.integer           :subscription_group_id
      t.string            :token_action

      t.timestamps
    end
		add_index :maily_herald_dispatches, :name, unique: true
    add_index :maily_herald_dispatches, :context_name
    add_index :maily_herald_dispatches, :trigger

    create_table :maily_herald_subscriptions do |t|
      t.string            :type,                                        null: false
      t.integer           :entity_id,                                   null: false
      t.string            :entity_type,                                 null: false
      t.integer           :dispatch_id
      t.string            :token,                                       null: false
      t.text              :settings
      t.text              :data
      t.boolean           :active,             default: false,       null: false
      t.datetime          :delivered_at

      t.timestamps
    end
		#add_index :maily_herald_subscriptions, [:type, :entity_id, :entity_type, :dispatch_id], unique: true, name: "index_maliy_herald_subscriptions_unique"

    create_table :maily_herald_logs do |t|
      t.integer           :entity_id,                                   null: false
      t.string            :entity_type,                                 null: false
      t.integer           :mailing_id
      t.string            :status,             default: "delivered", null: false
      t.text              :data
      t.datetime          :processed_at
    end

    create_table :maily_herald_subscription_groups do |t|
      t.string            :name,                                        null: false
      t.string            :title,                                       null: false
    end

    create_table :maily_herald_aggregated_subscriptions do |t|
      t.integer           :entity_id,                                   null: false
      t.string            :entity_type,                                 null: false
      t.integer           :group_id,                                    null: false
      t.boolean           :active,             default: false,       null: false
    end
  end
end
