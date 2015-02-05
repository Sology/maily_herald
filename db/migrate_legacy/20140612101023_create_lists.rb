class CreateLists < ActiveRecord::Migration
  def up
    create_table :maily_herald_lists do |t|
      t.string            :name,                                        null: false
      t.string            :title
      t.string            :context_name
    end

    remove_column :maily_herald_dispatches, :token_action
    remove_column :maily_herald_dispatches, :subscription_group_id
    remove_column :maily_herald_dispatches, :autosubscribe
    remove_column :maily_herald_dispatches, :start
    remove_column :maily_herald_dispatches, :start_var
    remove_column :maily_herald_dispatches, :trigger
    remove_column :maily_herald_dispatches, :enabled
    remove_column :maily_herald_dispatches, :context_name
    add_column :maily_herald_dispatches, :start_at, :text
    add_column :maily_herald_dispatches, :list_id, :integer
    add_column :maily_herald_dispatches, :state, :string, default: :disabled

    remove_column :maily_herald_subscriptions, :dispatch_id
    remove_column :maily_herald_subscriptions, :type
    add_column :maily_herald_subscriptions, :list_id, :integer
    #add_column :maily_herald_subscriptions, :next_delivery_at, :datetime

    drop_table :maily_herald_subscription_groups
    drop_table :maily_herald_aggregated_subscriptions

    rename_column :maily_herald_logs, :processed_at, :processing_at
    change_column :maily_herald_logs, :status, :string, default: nil
    add_column :maily_herald_logs, :entity_email, :string
  end
end
