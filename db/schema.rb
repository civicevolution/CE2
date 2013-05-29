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
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20130524215843) do

  create_table "attachments", force: true do |t|
    t.integer  "attachable_id",                           null: false
    t.string   "attachable_type",                         null: false
    t.integer  "user_id",                                 null: false
    t.string   "title"
    t.text     "description"
    t.integer  "version",                 default: 1,     null: false
    t.string   "status",                  default: "new", null: false
    t.string   "attachment_file_name"
    t.string   "attachment_content_type"
    t.integer  "attachment_file_size"
    t.datetime "attachment_updated_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "comment_versions", force: true do |t|
    t.string   "item_type",  null: false
    t.integer  "item_id",    null: false
    t.string   "event",      null: false
    t.string   "whodunnit"
    t.text     "object"
    t.datetime "created_at"
  end

  add_index "comment_versions", ["item_type", "item_id"], name: "index_comment_versions_on_item_type_and_item_id", using: :btree

  create_table "comments", force: true do |t|
    t.string   "type",                            null: false
    t.integer  "user_id",                         null: false
    t.integer  "conversation_id",                 null: false
    t.text     "text",                            null: false
    t.integer  "version",         default: 1
    t.string   "status",          default: "new"
    t.integer  "order_id"
    t.string   "purpose"
    t.string   "references"
    t.datetime "created_at",                      null: false
    t.datetime "updated_at",                      null: false
    t.integer  "ratings_cache",                                array: true
  end

  add_index "comments", ["conversation_id"], name: "index_comments_on_conversation_id", using: :btree
  add_index "comments", ["user_id"], name: "index_comments_on_user_id", using: :btree

  create_table "conversations", force: true do |t|
    t.integer  "question_id",                  null: false
    t.string   "status",      default: "open", null: false
    t.datetime "created_at",                   null: false
    t.datetime "updated_at",                   null: false
  end

  create_table "initiatives", force: true do |t|
    t.string   "title",       null: false
    t.text     "description", null: false
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
  end

  create_table "issues", force: true do |t|
    t.integer  "initiative_id",                  null: false
    t.integer  "user_id",                        null: false
    t.string   "title",                          null: false
    t.text     "description",                    null: false
    t.integer  "version",       default: 1
    t.string   "status",        default: "open", null: false
    t.string   "purpose"
    t.datetime "created_at",                     null: false
    t.datetime "updated_at",                     null: false
    t.string   "munged_title"
  end

  create_table "profiles", force: true do |t|
    t.integer  "user_id"
    t.string   "photo_file_name"
    t.string   "photo_content_type"
    t.integer  "photo_file_size"
    t.datetime "photo_updated_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "questions", force: true do |t|
    t.integer  "issue_id",                    null: false
    t.integer  "user_id",                     null: false
    t.text     "text",                        null: false
    t.integer  "version",    default: 1
    t.string   "status",     default: "open", null: false
    t.string   "purpose"
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
  end

  create_table "ratings", force: true do |t|
    t.integer "ratable_id",   null: false
    t.string  "ratable_type", null: false
    t.integer "version",      null: false
    t.integer "user_id",      null: false
    t.integer "rating",       null: false
  end

  create_table "roles", force: true do |t|
    t.string   "name"
    t.integer  "resource_id"
    t.string   "resource_type"
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
  end

  add_index "roles", ["name", "resource_type", "resource_id"], name: "index_roles_on_name_and_resource_type_and_resource_id", using: :btree
  add_index "roles", ["name"], name: "index_roles_on_name", using: :btree

  create_table "users", force: true do |t|
    t.string   "email",                  default: "", null: false
    t.string   "encrypted_password",     default: "", null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          default: 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.datetime "created_at",                          null: false
    t.datetime "updated_at",                          null: false
    t.string   "name"
    t.string   "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string   "unconfirmed_email"
    t.string   "authentication_token"
    t.string   "first_name"
    t.string   "last_name"
  end

  add_index "users", ["authentication_token"], name: "index_users_on_authentication_token", unique: true, using: :btree
  add_index "users", ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true, using: :btree
  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree

  create_table "users_roles", id: false, force: true do |t|
    t.integer "user_id"
    t.integer "role_id"
  end

  add_index "users_roles", ["user_id", "role_id"], name: "index_users_roles_on_user_id_and_role_id", using: :btree

end
