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

ActiveRecord::Schema[8.1].define(version: 2026_06_03_155644) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "pdf_imports", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.jsonb "pa_counts", default: {}, null: false
    t.date "report_date"
    t.bigint "store_id", null: false
    t.datetime "updated_at", null: false
    t.jsonb "user_counts", default: {}, null: false
    t.index ["store_id"], name: "index_pdf_imports_on_store_id"
  end

  create_table "stores", force: :cascade do |t|
    t.string "Storename"
    t.datetime "created_at", null: false
    t.integer "storenum"
    t.datetime "updated_at", null: false
  end

  create_table "trackers", force: :cascade do |t|
    t.string "art_name"
    t.string "art_num"
    t.integer "boh"
    t.text "comment"
    t.integer "counted"
    t.string "counter"
    t.datetime "created_at", null: false
    t.date "date"
    t.integer "diff_after_recount"
    t.integer "initial_diff"
    t.float "initial_loss"
    t.float "loss_after_recount"
    t.float "price"
    t.string "slid_h"
    t.integer "sss_inv_count"
    t.bigint "store_id", null: false
    t.datetime "updated_at", null: false
    t.index ["store_id"], name: "index_trackers_on_store_id"
  end

  add_foreign_key "pdf_imports", "stores"
  add_foreign_key "trackers", "stores"
end
