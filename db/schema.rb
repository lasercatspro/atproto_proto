# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2024_11_23_164114) do
  create_table "feed_items", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "post_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["post_id"], name: "index_feed_items_on_post_id"
    t.index ["user_id", "post_id"], name: "index_feed_items_on_user_id_and_post_id", unique: true
    t.index ["user_id"], name: "index_feed_items_on_user_id"
  end

  create_table "pds_tokens", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "pds_host"
    t.text "token"
    t.text "refresh_token"
    t.datetime "expires_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_pds_tokens_on_user_id"
  end

  create_table "posts", force: :cascade do |t|
    t.string "atproto_uri", null: false
    t.string "cid"
    t.text "content"
    t.string "type_name"
    t.string "language"
    t.string "reply_root_cid"
    t.string "reply_root_uri"
    t.string "reply_parent_cid"
    t.string "reply_parent_uri"
    t.json "facets"
    t.datetime "atproto_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["atproto_uri"], name: "index_posts_on_atproto_uri", unique: true
    t.index ["cid"], name: "index_posts_on_cid"
    t.index ["reply_parent_uri"], name: "index_posts_on_reply_parent_uri"
    t.index ["reply_root_uri"], name: "index_posts_on_reply_root_uri"
  end

  create_table "sessions", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "ip_address"
    t.string "user_agent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "handle"
    t.string "atproto_uri"
    t.string "did"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "feed_items", "posts"
  add_foreign_key "feed_items", "users"
  add_foreign_key "pds_tokens", "users"
  add_foreign_key "sessions", "users"
end
