class RemoveOverrideSubscriptionFromMailyHeraldDispatches < ActiveRecord::Migration[5.1]
  def change
    remove_column :maily_herald_dispatches, :override_subscription
  end
end
