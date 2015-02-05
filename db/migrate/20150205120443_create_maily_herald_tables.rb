class CreateMailyHeraldTables < ActiveRecord::Migration
  def change
    create_table :maily_herald_dispatches do |t|
      t.string            :type,                                        null: false
      t.integer           :sequence_id
      t.integer           :list_id,                                     null: false
      t.text              :conditions
      t.text              :start_at
      t.string            :mailer_name
      t.string            :name,                                        null: false
      t.string            :title
      t.string            :subject
      t.string            :from
      t.string            :state,             default: "disabled"
      t.text              :template
      t.integer           :absolute_delay
      t.integer           :period
      t.boolean           :override_subscription

      t.timestamps
    end
		add_index :maily_herald_dispatches, :name, unique: true

    create_table :maily_herald_subscriptions do |t|
      t.integer           :entity_id,                                   null: false
      t.integer           :list_id,                                     null: false
      t.string            :entity_type,                                 null: false
      t.string            :token,                                       null: false
      t.text              :settings
      t.text              :data
      t.boolean           :active,             default: false,       null: false
      t.datetime          :delivered_at

      t.timestamps
    end

    create_table :maily_herald_logs do |t|
      t.integer           :entity_id,                                   null: false
      t.string            :entity_type,                                 null: false
      t.string            :entity_email
      t.integer           :mailing_id
      t.string            :status,                                      null: false
      t.text              :data
      t.datetime          :processing_at
    end

    create_table :maily_herald_lists do |t|
      t.string            :name,                                        null: false
      t.string            :title
      t.string            :context_name
    end
  end
end
