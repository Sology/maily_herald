class AddOpenedToLogs < ActiveRecord::Migration[5.1]
  def change
    add_column :maily_herald_logs, :opened, :boolean, default: false

    MailyHerald::Log.all.each do |log|
      if log.data[:opens].present?
        log.update_column(:opened, true)
      end
    end
  end
end
