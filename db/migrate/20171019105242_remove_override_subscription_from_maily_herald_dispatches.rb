class RemoveOverrideSubscriptionFromMailyHeraldDispatches < ActiveRecord::Migration[4.2]
  def change
    remove_column :maily_herald_dispatches, :override_subscription, :boolean
  end
end
