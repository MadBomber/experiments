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

ActiveRecord::Schema[8.1].define(version: 2026_05_01_183348) do
  create_table "actors", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name", null: false
    t.string "preferred_model"
    t.string "preferred_provider"
    t.text "style_notes"
    t.datetime "updated_at", null: false
  end

  create_table "castings", force: :cascade do |t|
    t.integer "actor_id", null: false
    t.integer "character_id", null: false
    t.datetime "created_at", null: false
    t.integer "project_id", null: false
    t.datetime "updated_at", null: false
    t.index ["actor_id"], name: "index_castings_on_actor_id"
    t.index ["character_id", "project_id"], name: "index_castings_on_character_id_and_project_id", unique: true
    t.index ["character_id"], name: "index_castings_on_character_id"
    t.index ["project_id"], name: "index_castings_on_project_id"
  end

  create_table "character_arcs", force: :cascade do |t|
    t.text "arc_description"
    t.text "arc_end_goal"
    t.text "arc_start_state"
    t.integer "character_id", null: false
    t.datetime "created_at", null: false
    t.text "current_position"
    t.text "key_turning_points"
    t.integer "project_id", null: false
    t.datetime "updated_at", null: false
    t.index ["character_id", "project_id"], name: "index_character_arcs_on_character_id_and_project_id", unique: true
    t.index ["character_id"], name: "index_character_arcs_on_character_id"
    t.index ["project_id"], name: "index_character_arcs_on_project_id"
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

  create_table "projects", force: :cascade do |t|
    t.text "conflict_escalation"
    t.text "conflicts"
    t.text "core_stakes"
    t.datetime "created_at", null: false
    t.integer "created_by"
    t.text "description"
    t.text "differentiation_notes"
    t.string "genre"
    t.text "logline"
    t.text "marketing_angle"
    t.text "plot_points"
    t.string "prep_status", default: "concept", null: false
    t.text "research_notes"
    t.text "setting"
    t.text "similar_works"
    t.text "story_arc"
    t.text "synopsis"
    t.string "tagline"
    t.integer "target_page_count"
    t.integer "target_runtime_minutes"
    t.string "title", null: false
    t.text "title_alternatives"
    t.text "tone"
    t.datetime "updated_at", null: false
    t.text "visual_references"
    t.text "world_building_notes"
  end

  create_table "roles", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_roles_on_name", unique: true
  end

  create_table "stories", force: :cascade do |t|
    t.string "act_structure", default: "three_act", null: false
    t.text "acts"
    t.text "conflict_escalation"
    t.datetime "created_at", null: false
    t.text "narrative_arc"
    t.text "plot_points"
    t.integer "project_id", null: false
    t.text "resolution"
    t.integer "target_page_count"
    t.string "title"
    t.datetime "updated_at", null: false
    t.index ["project_id"], name: "index_stories_on_project_id"
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

  add_foreign_key "castings", "actors"
  add_foreign_key "castings", "characters"
  add_foreign_key "castings", "projects"
  add_foreign_key "character_arcs", "characters"
  add_foreign_key "character_arcs", "projects"
  add_foreign_key "stories", "projects"
  add_foreign_key "user_roles", "roles"
  add_foreign_key "user_roles", "users"
end
