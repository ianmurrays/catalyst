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

ActiveRecord::Schema[8.0].define(version: 2025_09_06_093158) do
  create_table "users", force: :cascade do |t|
    t.string "auth0_sub", null: false
    t.string "display_name"
    t.text "bio"
    t.string "phone"
    t.json "preferences"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "email"
    t.string "email_source", default: "manual"
    t.index ["auth0_sub"], name: "index_users_on_auth0_sub", unique: true
    t.index ["email_source"], name: "index_users_on_email_source"
  end
end
