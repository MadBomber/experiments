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

ActiveRecord::Schema[8.1].define(version: 2026_05_01_205730) do
  create_table "actors", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name", null: false
    t.string "preferred_model"
    t.string "preferred_provider"
    t.text "style_notes"
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_actors_on_name"
  end

  create_table "beats", force: :cascade do |t|
    t.integer "act"
    t.string "beat_type", default: "general", null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.integer "position", default: 0, null: false
    t.integer "project_id", null: false
    t.integer "scene_id"
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["beat_type"], name: "index_beats_on_beat_type"
    t.index ["project_id", "position"], name: "index_beats_on_project_id_and_position"
    t.index ["project_id"], name: "index_beats_on_project_id"
    t.index ["scene_id"], name: "index_beats_on_scene_id"
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
    t.string "role_in_story"
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
    t.text "external_want"
    t.integer "input_tokens", default: 0, null: false
    t.text "internal_conflict"
    t.text "internal_need"
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
    t.index ["name"], name: "index_characters_on_name"
  end

  create_table "passwordless_sessions", force: :cascade do |t|
    t.integer "authenticatable_id"
    t.string "authenticatable_type"
    t.datetime "claimed_at", precision: nil
    t.datetime "created_at", null: false
    t.datetime "expires_at", precision: nil, null: false
    t.string "identifier", null: false
    t.datetime "timeout_at", precision: nil, null: false
    t.string "token_digest", null: false
    t.datetime "updated_at", null: false
    t.index ["authenticatable_type", "authenticatable_id"], name: "authenticatable"
    t.index ["identifier"], name: "index_passwordless_sessions_on_identifier", unique: true
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
    t.string "origin_approach"
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
    t.text "thematic_question"
    t.text "theme"
    t.string "title", null: false
    t.text "title_alternatives"
    t.text "tone"
    t.datetime "updated_at", null: false
    t.text "visual_references"
    t.text "world_building_notes"
    t.index ["created_by"], name: "index_projects_on_created_by"
    t.index ["prep_status"], name: "index_projects_on_prep_status"
  end

  create_table "research_materials", force: :cascade do |t|
    t.text "accuracy_requirements"
    t.string "category", default: "other", null: false
    t.integer "character_id"
    t.datetime "created_at", null: false
    t.text "key_facts"
    t.integer "project_id", null: false
    t.integer "scene_id"
    t.text "sources"
    t.string "subject", null: false
    t.text "summary"
    t.datetime "updated_at", null: false
    t.text "world_building_notes"
    t.index ["category"], name: "index_research_materials_on_category"
    t.index ["character_id"], name: "index_research_materials_on_character_id"
    t.index ["project_id"], name: "index_research_materials_on_project_id"
    t.index ["scene_id"], name: "index_research_materials_on_scene_id"
  end

  create_table "roles", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_roles_on_name", unique: true
  end

  create_table "scene_characters", force: :cascade do |t|
    t.text "arc_advancement"
    t.integer "character_id", null: false
    t.datetime "created_at", null: false
    t.integer "scene_id", null: false
    t.text "scene_objectives"
    t.datetime "updated_at", null: false
    t.index ["character_id"], name: "index_scene_characters_on_character_id"
    t.index ["scene_id", "character_id"], name: "index_scene_characters_on_scene_id_and_character_id", unique: true
    t.index ["scene_id"], name: "index_scene_characters_on_scene_id"
  end

  create_table "scene_comments", force: :cascade do |t|
    t.text "body", null: false
    t.datetime "created_at", null: false
    t.boolean "resolved", default: false, null: false
    t.integer "resolved_by_id"
    t.integer "scene_id", null: false
    t.integer "transcript_line_id"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["resolved_by_id"], name: "index_scene_comments_on_resolved_by_id"
    t.index ["scene_id", "resolved"], name: "index_scene_comments_on_scene_id_and_resolved"
    t.index ["scene_id"], name: "index_scene_comments_on_scene_id"
    t.index ["transcript_line_id"], name: "index_scene_comments_on_transcript_line_id"
    t.index ["user_id"], name: "index_scene_comments_on_user_id"
  end

  create_table "scene_runs", force: :cascade do |t|
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.integer "scene_id", null: false
    t.datetime "started_at"
    t.integer "started_by"
    t.string "status", default: "queued", null: false
    t.datetime "updated_at", null: false
    t.index ["scene_id"], name: "index_scene_runs_on_scene_id"
    t.index ["started_by"], name: "index_scene_runs_on_started_by"
    t.index ["status"], name: "index_scene_runs_on_status"
  end

  create_table "scenes", force: :cascade do |t|
    t.text "atmosphere"
    t.text "beat_structure"
    t.text "context"
    t.datetime "created_at", null: false
    t.decimal "estimated_pages", precision: 4, scale: 1
    t.string "interior_exterior"
    t.text "key_imagery"
    t.string "location"
    t.string "name", null: false
    t.integer "number", null: false
    t.integer "position"
    t.integer "project_id", null: false
    t.text "rejection_notes"
    t.datetime "released_at"
    t.integer "released_by"
    t.integer "revision_number", default: 1, null: false
    t.string "scene_heading_time"
    t.string "status", default: "draft", null: false
    t.datetime "submitted_at"
    t.string "transition_out", default: "cut_to"
    t.datetime "updated_at", null: false
    t.integer "week"
    t.index ["project_id", "number"], name: "index_scenes_on_project_id_and_number"
    t.index ["project_id", "position"], name: "index_scenes_on_project_id_and_position"
    t.index ["project_id"], name: "index_scenes_on_project_id"
    t.index ["released_by"], name: "index_scenes_on_released_by"
    t.index ["status"], name: "index_scenes_on_status"
  end

  create_table "stories", force: :cascade do |t|
    t.text "a_story"
    t.string "act_structure", default: "three_act", null: false
    t.text "acts"
    t.text "b_story"
    t.text "conflict_escalation"
    t.datetime "created_at", null: false
    t.text "narrative_arc"
    t.string "plot_archetype"
    t.text "plot_points"
    t.integer "project_id", null: false
    t.text "resolution"
    t.integer "target_page_count"
    t.string "title"
    t.datetime "updated_at", null: false
    t.index ["act_structure"], name: "index_stories_on_act_structure"
    t.index ["project_id"], name: "index_stories_on_project_id"
  end

  create_table "transcript_lines", force: :cascade do |t|
    t.string "addressing"
    t.integer "character_id"
    t.text "content", null: false
    t.datetime "created_at", null: false
    t.string "element_type", default: "dialogue"
    t.string "emotion"
    t.string "parenthetical"
    t.integer "position", null: false
    t.integer "scene_run_id", null: false
    t.datetime "updated_at", null: false
    t.string "voice_qualifier", default: "none"
    t.index ["character_id"], name: "index_transcript_lines_on_character_id"
    t.index ["scene_run_id", "position"], name: "index_transcript_lines_on_scene_run_id_and_position"
    t.index ["scene_run_id"], name: "index_transcript_lines_on_scene_run_id"
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

  add_foreign_key "beats", "projects"
  add_foreign_key "castings", "actors"
  add_foreign_key "castings", "characters"
  add_foreign_key "castings", "projects"
  add_foreign_key "character_arcs", "characters"
  add_foreign_key "character_arcs", "projects"
  add_foreign_key "research_materials", "projects"
  add_foreign_key "scene_characters", "characters"
  add_foreign_key "scene_characters", "scenes"
  add_foreign_key "scene_comments", "scenes"
  add_foreign_key "scene_comments", "users"
  add_foreign_key "scene_runs", "scenes"
  add_foreign_key "scenes", "projects"
  add_foreign_key "stories", "projects"
  add_foreign_key "transcript_lines", "characters", on_delete: :nullify
  add_foreign_key "transcript_lines", "scene_runs"
  add_foreign_key "user_roles", "roles"
  add_foreign_key "user_roles", "users"
end
