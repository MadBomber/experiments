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

ActiveRecord::Schema[8.1].define(version: 2026_05_01_183146) do
  create_table "actors", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name", null: false
    t.string "preferred_model"
    t.string "preferred_provider"
    t.text "style_notes"
    t.datetime "updated_at", null: false
  end

  create_table "characters", force: :cascade do |t|
    t.string "archetype"
    t.text "character_arc"
    t.datetime "created_at", null: false
    t.text "data"
    t.integer "input_tokens", default: 0, null: false
    t.text "internal_conflict"
    t.text "mannerisms"
    t.string "model"
    t.text "motivation"
    t.string "name", null: false
    t.integer "output_tokens", default: 0, null: false
    t.text "personality"
    t.text "physical_description"
    t.string "provider"
    t.integer "total_tokens", default: 0, null: false
    t.datetime "updated_at", null: false
    t.text "voice_pattern"
  end

  create_table "roles", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_roles_on_name", unique: true
  end

  create_table "user_roles", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "role_id", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["role_id"], name: "index_user_roles_on_role_id"
    t.index ["user_id", "role_id"], name: "index_user_roles_on_user_id_and_role_id", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.integer "actor_id"
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.string "name"
    t.datetime "updated_at", null: false
    t.index ["actor_id"], name: "index_users_on_actor_id"
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "user_roles", "roles"
  add_foreign_key "user_roles", "users"
end
