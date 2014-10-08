class CreateLists < ActiveRecord::Migration
  def up
    create_table :maily_herald_lists do |t|
      t.string            :name,                                        :null => false
      t.string            :title
      t.string            :context_name
      #t.text              :autosubscribe_condition
      t.string            :token_action
    end

    remove_column :maily_herald_dispatches, :token_action
    remove_column :maily_herald_dispatches, :subscription_group_id
    remove_column :maily_herald_dispatches, :autosubscribe
    remove_column :maily_herald_dispatches, :start
    remove_column :maily_herald_dispatches, :start_var
    remove_column :maily_herald_dispatches, :trigger
    add_column :maily_herald_dispatches, :start_at, :text
    add_column :maily_herald_dispatches, :list_id, :integer

    remove_column :maily_herald_subscriptions, :dispatch_id
    remove_column :maily_herald_subscriptions, :type
    add_column :maily_herald_subscriptions, :list_id, :integer
    add_column :maily_herald_subscriptions, :next_delivery_at, :datetime

    drop_table :maily_herald_subscription_groups
    drop_table :maily_herald_aggregated_subscriptions

    rename_column :maily_herald_logs, :processed_at, :processing_at
    change_column :maily_herald_logs, :status, :string, :default => nil
  end
end
