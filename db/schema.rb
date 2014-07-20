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

ActiveRecord::Schema.define(version: 20140719154550) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "hstore"

  create_table "activity_reports", force: true do |t|
    t.string   "action"
    t.integer  "user_id"
    t.string   "conversation_code"
    t.inet     "ip_address"
    t.hstore   "details"
    t.datetime "notification_sent_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "agenda_component_threads", force: true do |t|
    t.integer  "agenda_id"
    t.integer  "child_id"
    t.integer  "parent_id"
    t.integer  "order_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "agenda_components", force: true do |t|
    t.integer  "agenda_id"
    t.string   "code"
    t.string   "descriptive_name"
    t.string   "type"
    t.json     "input"
    t.json     "output"
    t.string   "status"
    t.datetime "starts_at"
    t.datetime "ends_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "menu_roles",       array: true
  end

  create_table "agenda_roles", force: true do |t|
    t.integer  "agenda_id"
    t.string   "name"
    t.integer  "identifier"
    t.string   "access_code"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "agendas", force: true do |t|
    t.string   "title"
    t.text     "description"
    t.string   "code"
    t.string   "access_code"
    t.string   "template_name"
    t.boolean  "list"
    t.hstore   "status"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "test_mode",     default: true
    t.json     "details"
  end

  create_table "attachments", force: true do |t|
    t.integer  "attachable_id",                           null: false
    t.string   "attachable_type",                         null: false
    t.integer  "user_id",                                 null: false
    t.integer  "version",                 default: 1,     null: false
    t.string   "status",                  default: "new", null: false
    t.string   "attachment_file_name"
    t.string   "attachment_content_type"
    t.integer  "attachment_file_size"
    t.datetime "attachment_updated_at"
    t.integer  "image_height"
    t.integer  "image_width"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "autosaves", force: true do |t|
    t.integer  "user_id"
    t.string   "code"
    t.json     "data"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "belongs_to_user_id"
  end

  add_index "autosaves", ["code"], name: "index_autosaves_on_code", unique: true, using: :btree
  add_index "autosaves", ["user_id"], name: "index_autosaves_on_user_id", unique: true, using: :btree

  create_table "bookmarks", force: true do |t|
    t.integer  "user_id"
    t.integer  "target_id"
    t.string   "target_type"
    t.integer  "version"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "bookmarks", ["user_id"], name: "index_bookmarks_on_user_id", using: :btree

  create_table "brand_tags", force: true do |t|
    t.string   "name",                         null: false
    t.boolean  "published",     default: true
    t.integer  "user_id"
    t.integer  "admin_user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "comment_tag_assignments", force: true do |t|
    t.integer  "tag_id"
    t.integer  "comment_id"
    t.integer  "conversation_id"
    t.integer  "user_id"
    t.boolean  "star"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "comment_tag_assignments", ["tag_id", "comment_id", "user_id"], name: "index_comment_tag_assignments_on_tag_comment_and_user_id", unique: true, using: :btree

  create_table "comment_threads", force: true do |t|
    t.integer  "child_id",   null: false
    t.integer  "parent_id",  null: false
    t.integer  "order_id",   null: false
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
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "ratings_cache",                                array: true
    t.boolean  "published",       default: false
    t.string   "tag_name"
    t.json     "elements"
  end

  add_index "comments", ["conversation_id"], name: "index_comments_on_conversation_id", using: :btree
  add_index "comments", ["user_id"], name: "index_comments_on_user_id", using: :btree

  create_table "contacts", force: true do |t|
    t.integer  "user_id"
    t.string   "first_name"
    t.string   "last_name"
    t.string   "email"
    t.text     "text"
    t.string   "reference_type"
    t.string   "reference_id"
    t.hstore   "action"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "conversations", force: true do |t|
    t.string   "code",                                null: false
    t.integer  "user_id",                             null: false
    t.datetime "starts_at"
    t.datetime "ends_at"
    t.hstore   "privacy"
    t.boolean  "list",                default: false
    t.boolean  "published",           default: false
    t.string   "status",              default: "new", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "daily_report_hour",   default: 7
    t.datetime "last_report_sent_at"
    t.json     "details"
    t.integer  "agenda_id"
  end

  add_index "conversations", ["code"], name: "index_conversations_on_code", unique: true, using: :btree

  create_table "conversations_tags", force: true do |t|
    t.integer "conversation_id"
    t.integer "tag_id"
    t.integer "published",       default: 1
  end

  create_table "delayed_jobs", force: true do |t|
    t.integer  "priority",   default: 0, null: false
    t.integer  "attempts",   default: 0, null: false
    t.text     "handler",                null: false
    t.text     "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by"
    t.string   "queue"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "delayed_jobs", ["priority", "run_at"], name: "delayed_jobs_priority", using: :btree

  create_table "draft_comments", force: true do |t|
    t.string   "code"
    t.json     "data"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "draft_comments", ["code"], name: "index_draft_comments_on_code", unique: true, using: :btree

  create_table "flagged_items", force: true do |t|
    t.integer  "user_id"
    t.integer  "conversation_id"
    t.integer  "target_id"
    t.string   "target_type"
    t.string   "category"
    t.text     "statement"
    t.integer  "version"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "flagged_items", ["target_id", "target_type"], name: "index_flagged_items_on_target_id_and_target_type", using: :btree

  create_table "follow_ces", force: true do |t|
    t.string   "email",      null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "guest_confirmations", force: true do |t|
    t.string   "email"
    t.string   "first_name"
    t.string   "last_name"
    t.string   "code"
    t.integer  "conversation_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "guest_confirmations", ["code"], name: "index_guest_confirmations_on_code", unique: true, using: :btree

  create_table "guest_posts", force: true do |t|
    t.string   "post_type"
    t.integer  "user_id"
    t.string   "first_name"
    t.string   "last_name"
    t.string   "email"
    t.integer  "conversation_id"
    t.text     "text"
    t.string   "purpose"
    t.integer  "reply_to_id"
    t.integer  "reply_to_version"
    t.boolean  "request_to_join"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "invites", force: true do |t|
    t.integer  "sender_user_id"
    t.string   "first_name"
    t.string   "last_name"
    t.string   "email"
    t.text     "text"
    t.string   "code"
    t.integer  "conversation_id"
    t.hstore   "options"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "invites", ["code"], name: "index_invites_on_code", unique: true, using: :btree

  create_table "log_emails", force: true do |t|
    t.string   "token"
    t.string   "email"
    t.string   "subject"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "log_flagged_items", force: true do |t|
    t.integer  "user_id"
    t.integer  "conversation_id"
    t.integer  "target_id"
    t.string   "target_type"
    t.string   "category"
    t.text     "statement"
    t.integer  "version"
    t.datetime "posted_at"
    t.hstore   "review_details"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "log_flagged_items", ["target_id", "target_type"], name: "index_log_flagged_items_on_target_id_and_target_type", using: :btree

  create_table "log_guest_confirmations", force: true do |t|
    t.integer  "user_id"
    t.integer  "conversation_id"
    t.datetime "posted_at"
    t.hstore   "details"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "log_guest_posts", force: true do |t|
    t.string   "post_type"
    t.integer  "user_id"
    t.string   "first_name"
    t.string   "last_name"
    t.string   "email"
    t.integer  "conversation_id"
    t.text     "text"
    t.string   "purpose"
    t.integer  "reply_to_id"
    t.integer  "reply_to_version"
    t.boolean  "request_to_join"
    t.datetime "posted_at"
    t.hstore   "review_details"
    t.integer  "comment_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "log_invites", force: true do |t|
    t.integer  "sender_user_id"
    t.string   "first_name"
    t.string   "last_name"
    t.string   "email"
    t.text     "text"
    t.string   "code"
    t.integer  "conversation_id"
    t.hstore   "options"
    t.hstore   "details"
    t.integer  "user_id"
    t.datetime "invited_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "log_reviewed_comments", force: true do |t|
    t.integer  "comment_id"
    t.string   "type"
    t.integer  "user_id"
    t.integer  "conversation_id"
    t.text     "text"
    t.integer  "version"
    t.string   "status"
    t.integer  "order_id"
    t.string   "purpose"
    t.integer  "references"
    t.integer  "published"
    t.datetime "posted_at"
    t.hstore   "review_details"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "mca_criteria", force: true do |t|
    t.integer  "multi_criteria_analysis_id"
    t.string   "category"
    t.string   "title"
    t.text     "text"
    t.integer  "order_id"
    t.string   "range"
    t.float    "weight"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "mca_option_evaluations", force: true do |t|
    t.integer  "user_id"
    t.integer  "mca_option_id"
    t.integer  "order_id"
    t.string   "category"
    t.string   "status"
    t.text     "notes"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "mca_options", force: true do |t|
    t.integer  "multi_criteria_analysis_id"
    t.string   "title"
    t.text     "text"
    t.integer  "order_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.hstore   "details"
    t.string   "category"
    t.json     "data"
  end

  create_table "mca_ratings", force: true do |t|
    t.integer  "mca_option_evaluation_id"
    t.integer  "mca_criteria_id"
    t.integer  "rating"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "mentions", force: true do |t|
    t.integer  "comment_id"
    t.integer  "version"
    t.integer  "user_id"
    t.integer  "mentioned_user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "multi_criteria_analyses", force: true do |t|
    t.integer  "agenda_id"
    t.string   "title"
    t.string   "description"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.hstore   "details"
    t.json     "data"
  end

  create_table "notification_requests", force: true do |t|
    t.integer  "conversation_id", null: false
    t.integer  "user_id",         null: false
    t.boolean  "immediate_me"
    t.boolean  "immediate_all"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "send_daily"
  end

  add_index "notification_requests", ["conversation_id", "user_id"], name: "index_notification_requests_on_conversation_id_and_user_id", using: :btree

  create_table "parked_comments", force: true do |t|
    t.integer  "conversation_id"
    t.integer  "user_id"
    t.integer  "parked_ids",      array: true
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "pro_con_votes", force: true do |t|
    t.integer  "comment_id"
    t.integer  "pro_votes"
    t.integer  "con_votes"
    t.datetime "created_at"
    t.datetime "updated_at"
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

  create_table "ratings", force: true do |t|
    t.integer "ratable_id",   null: false
    t.string  "ratable_type", null: false
    t.integer "version",      null: false
    t.integer "user_id",      null: false
    t.integer "rating",       null: false
  end

  create_table "recommendation_votes", force: true do |t|
    t.integer  "group_id"
    t.integer  "voter_id"
    t.integer  "conversation_id"
    t.integer  "recommendation"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "num_of_votes",    default: 0
  end

  create_table "replies", force: true do |t|
    t.integer  "comment_id",      null: false
    t.integer  "reply_to_id",     null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "version"
    t.boolean  "quote"
    t.string   "author"
    t.string   "code"
    t.integer  "user_id"
    t.integer  "conversation_id"
  end

  create_table "report_images", force: true do |t|
    t.integer  "report_id"
    t.string   "image_file_name"
    t.string   "image_content_type"
    t.integer  "image_file_size"
    t.datetime "image_updated_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "reports", force: true do |t|
    t.integer  "user_id"
    t.string   "agenda_code"
    t.string   "title"
    t.string   "source_type"
    t.string   "source_code"
    t.string   "layout"
    t.integer  "version",     default: 1
    t.string   "header"
    t.hstore   "settings"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "roles", force: true do |t|
    t.string   "name"
    t.integer  "resource_id"
    t.string   "resource_type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "roles", ["name", "resource_type", "resource_id"], name: "index_roles_on_name_and_resource_type_and_resource_id", using: :btree
  add_index "roles", ["name"], name: "index_roles_on_name", using: :btree

  create_table "tags", force: true do |t|
    t.string   "text"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "tags", ["text"], name: "index_tags_on_text", unique: true, using: :btree

  create_table "theme_points", force: true do |t|
    t.integer  "group_id"
    t.integer  "theme_id"
    t.integer  "points"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "voter_id"
    t.string   "code"
  end

  create_table "theme_votes", force: true do |t|
    t.integer  "group_id"
    t.integer  "voter_id"
    t.integer  "theme_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "code"
  end

  create_table "ui_labels", force: true do |t|
    t.string   "tag"
    t.string   "language"
    t.string   "text"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "unsubscribes", force: true do |t|
    t.string   "email"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "subject"
  end

  add_index "unsubscribes", ["email"], name: "index_unsubscribes_on_email", unique: true, using: :btree

  create_table "users", force: true do |t|
    t.string   "email",                  default: "",   null: false
    t.string   "encrypted_password",     default: "",   null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          default: 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.string   "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string   "unconfirmed_email"
    t.string   "authentication_token"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "name"
    t.string   "first_name",                            null: false
    t.string   "last_name",                             null: false
    t.boolean  "email_ok",               default: true
    t.integer  "name_count"
    t.string   "code"
  end

  add_index "users", ["authentication_token"], name: "index_users_on_authentication_token", unique: true, using: :btree
  add_index "users", ["code"], name: "index_users_on_code", unique: true, using: :btree
  add_index "users", ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true, using: :btree
  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
  add_index "users", ["name"], name: "index_users_on_name", unique: true, using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree

  create_table "users_roles", id: false, force: true do |t|
    t.integer "user_id"
    t.integer "role_id"
  end

  add_index "users_roles", ["user_id", "role_id"], name: "index_users_roles_on_user_id_and_role_id", using: :btree

end
