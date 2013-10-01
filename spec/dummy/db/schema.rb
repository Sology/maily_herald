# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20130723074347) do

  create_table "maily_herald_aggregated_subscriptions", :force => true do |t|
    t.integer "entity_id",                      :null => false
    t.string  "entity_type",                    :null => false
    t.integer "group_id",                       :null => false
    t.boolean "active",      :default => false, :null => false
  end

  create_table "maily_herald_dispatches", :force => true do |t|
    t.string   "type",                                     :null => false
    t.integer  "sequence_id"
    t.string   "context_name"
    t.text     "conditions"
    t.string   "trigger"
    t.string   "mailer_name"
    t.string   "name",                                     :null => false
    t.string   "title"
    t.string   "subject"
    t.string   "from"
    t.text     "template"
    t.integer  "absolute_delay"
    t.datetime "start"
    t.text     "start_var"
    t.integer  "period"
    t.boolean  "enabled",               :default => false
    t.boolean  "autosubscribe"
    t.boolean  "override_subscription"
    t.integer  "subscription_group_id"
    t.string   "token_action"
    t.datetime "created_at",                               :null => false
    t.datetime "updated_at",                               :null => false
  end

  add_index "maily_herald_dispatches", ["context_name"], :name => "index_maily_herald_dispatches_on_context_name"
  add_index "maily_herald_dispatches", ["name"], :name => "index_maily_herald_dispatches_on_name", :unique => true
  add_index "maily_herald_dispatches", ["trigger"], :name => "index_maily_herald_dispatches_on_trigger"

  create_table "maily_herald_logs", :force => true do |t|
    t.integer  "entity_id",                             :null => false
    t.string   "entity_type",                           :null => false
    t.integer  "mailing_id"
    t.string   "status",       :default => "delivered", :null => false
    t.text     "data"
    t.datetime "processed_at"
  end

  create_table "maily_herald_subscription_groups", :force => true do |t|
    t.string "name",  :null => false
    t.string "title", :null => false
  end

  create_table "maily_herald_subscriptions", :force => true do |t|
    t.string   "type",                            :null => false
    t.integer  "entity_id",                       :null => false
    t.string   "entity_type",                     :null => false
    t.integer  "dispatch_id"
    t.string   "token",                           :null => false
    t.text     "settings"
    t.text     "data"
    t.boolean  "active",       :default => false, :null => false
    t.datetime "delivered_at"
    t.datetime "created_at",                      :null => false
    t.datetime "updated_at",                      :null => false
  end

  create_table "users", :force => true do |t|
    t.string   "name"
    t.string   "email"
    t.boolean  "weekly_notifications", :default => true
    t.datetime "created_at",                             :null => false
    t.datetime "updated_at",                             :null => false
  end

end
