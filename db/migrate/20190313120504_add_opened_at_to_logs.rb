class AddOpenedAtToLogs < ActiveRecord::Migration[5.1]
  def change
    add_column :maily_herald_logs, :opened_at, :datetime

    reversible do |dir|
      dir.up do
        MailyHerald::Log.all.each do |log|
          if log.data[:opens].present?
            first_open = log.data[:opens].first
            log.update_column(:opened_at, first_open[:opened_at])
          end
        end
      end
    end
  end
end
