class CreateMailyHeraldTables < ActiveRecord::Migration
  def change
    create_table :maily_herald_mailings do |t|
      t.integer 					:sequence_id
			t.string 						:token
			t.string						:context
			t.text							:conditions
			t.string						:name
			t.string						:title
			t.string						:sender
			t.text							:template
			t.integer						:delay

      t.timestamps
    end

		create_table :maily_herald_sequences do |t|
			t.string 						:token
			t.string						:context
			t.string						:name
			t.integer						:mode
			t.datetime					:start
			t.text							:start_expr
			t.integer						:period

      t.timestamps
		end

		create_table :maily_herald_mailing_records do |t|
			t.integer 					:entity_id
			t.string						:entity_type
			t.integer						:mailing_id
			t.string						:mailing_type
			t.text							:settings
			t.text							:status
			t.datetime					:last_delivery
		end
  end
end
