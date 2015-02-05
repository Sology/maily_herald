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

ActiveRecord::Schema.define(:version => 20150205120443) do

  create_table "maily_herald_dispatches", :force => true do |t|
    t.string   "type",                                          :null => false
    t.integer  "sequence_id"
    t.integer  "list_id",                                       :null => false
    t.text     "conditions"
    t.text     "start_at"
    t.string   "mailer_name"
    t.string   "name",                                          :null => false
    t.string   "title"
    t.string   "subject"
    t.string   "from"
    t.string   "state",                 :default => "disabled"
    t.text     "template"
    t.integer  "absolute_delay"
    t.integer  "period"
    t.boolean  "override_subscription"
    t.datetime "created_at",                                    :null => false
    t.datetime "updated_at",                                    :null => false
  end

  add_index "maily_herald_dispatches", ["name"], :name => "index_maily_herald_dispatches_on_name", :unique => true

  create_table "maily_herald_lists", :force => true do |t|
    t.string "name",         :null => false
    t.string "title"
    t.string "context_name"
  end

  create_table "maily_herald_logs", :force => true do |t|
    t.integer  "entity_id",     :null => false
    t.string   "entity_type",   :null => false
    t.string   "entity_email"
    t.integer  "mailing_id"
    t.string   "status",        :null => false
    t.text     "data"
    t.datetime "processing_at"
  end

  create_table "maily_herald_subscriptions", :force => true do |t|
    t.integer  "entity_id",                       :null => false
    t.integer  "list_id",                         :null => false
    t.string   "entity_type",                     :null => false
    t.string   "token",                           :null => false
    t.text     "settings"
    t.text     "data"
    t.boolean  "active",       :default => false, :null => false
    t.datetime "delivered_at"
    t.datetime "created_at",                      :null => false
    t.datetime "updated_at",                      :null => false
  end

  create_table "products", :force => true do |t|
    t.string   "name"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "users", :force => true do |t|
    t.string   "name"
    t.string   "email"
    t.boolean  "weekly_notifications", :default => true
    t.boolean  "active",               :default => true
    t.datetime "created_at",                             :null => false
    t.datetime "updated_at",                             :null => false
  end

end
