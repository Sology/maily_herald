class AddAutosubscribeToMailyHeraldSubscriptionGroups < ActiveRecord::Migration
  def change
    add_column :maily_herald_subscription_groups, :autosubscribe, :boolean
  end
end
