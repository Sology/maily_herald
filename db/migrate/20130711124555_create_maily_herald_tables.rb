class CreateMailyHeraldTables < ActiveRecord::Migration
  def change
    create_table :maily_herald_mailings do |t|
      t.integer           :sequence_id
      t.string            :context_name,                                :null => false
      t.text              :conditions
      t.string            :trigger,           :default => 'manual',     :null => false
      t.string            :mailer_name,       :default => 'generic',    :null => false
      t.string            :name,                                        :null => false
      t.string            :title,                                       :null => false
      t.string            :from
      t.text              :template,                                    :null => false
      t.integer           :delay

      t.timestamps
    end
		add_index :maily_herald_mailings, :name, :unique => true
    add_index :maily_herald_mailings, :context_name
    add_index :maily_herald_mailings, :trigger

    create_table :maily_herald_sequences do |t|
      t.string            :context_name,                                :null => false
      t.string            :name,                                        :null => false
      t.string            :mode,              :default => 'periodical', :null => false 
      t.datetime          :start
      t.text              :start_expr
      t.integer           :period

      t.timestamps
    end
    add_index :maily_herald_sequences, :context_name
    add_index :maily_herald_sequences, :mode

    create_table :maily_herald_mailing_records do |t|
      t.integer           :entity_id,                                   :null => false
      t.string            :entity_type,                                 :null => false
      t.integer           :mailing_id,                                  :null => false
      t.string            :mailing_type,                                :null => false
      t.string            :token,                                       :null => false
      t.text              :settings
      t.text              :status
      t.datetime          :last_delivery
    end
  end
end
