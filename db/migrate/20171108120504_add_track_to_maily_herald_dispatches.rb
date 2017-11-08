class AddTrackToMailyHeraldDispatches < ActiveRecord::Migration[4.2]
  def change
    add_column :maily_herald_dispatches, :track, :boolean, default: true
  end
end
