class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.string      :name
      t.string      :email
      t.boolean     :weekly_notifications, default: true
      t.boolean     :active, default: true

      t.timestamps
    end

    create_table :products do |t|
      t.string      :name

      t.timestamps
    end
  end
end
