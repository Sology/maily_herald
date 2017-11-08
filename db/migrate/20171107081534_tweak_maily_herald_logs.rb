class TweakMailyHeraldLogs < ActiveRecord::Migration[4.2]
  def change
    add_column :maily_herald_logs, :token, :string
  end
end
