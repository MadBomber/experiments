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

ActiveRecord::Schema.define(version: 20171025230918) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "alerts", force: :cascade do |t|
    t.text     "description"
    t.datetime "date_completed"
    t.datetime "created_at",                       null: false
    t.datetime "updated_at",                       null: false
    t.string   "notification_type"
    t.integer  "site"
    t.boolean  "active",            default: true
    t.integer  "requested_by",                     null: false
    t.integer  "completed_by"
  end

  create_table "appointment_objects", force: :cascade do |t|
    t.text     "xml"
    t.integer  "contention_id"
    t.boolean  "active"
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
    t.string   "exam_appointment_id"
    t.string   "examination_identifier"
  end

  create_table "boilerplate_messages", force: :cascade do |t|
    t.string   "name"
    t.string   "content"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "boilerplate_messages_dbq_informations", force: :cascade do |t|
    t.integer "boilerplate_message_id", null: false
    t.integer "dbq_information_id",     null: false
    t.integer "position"
  end

  add_index "boilerplate_messages_dbq_informations", ["boilerplate_message_id", "dbq_information_id"], name: "idx_boilerplate_message_dbq_info", using: :btree

  create_table "care_categories", force: :cascade do |t|
    t.string   "sequence",   null: false
    t.string   "title",      null: false
    t.datetime "deleted_at"
  end

  add_index "care_categories", ["deleted_at"], name: "index_care_categories_on_deleted_at", using: :btree
  add_index "care_categories", ["sequence"], name: "index_care_categories_on_sequence", using: :btree
  add_index "care_categories", ["title"], name: "index_care_categories_on_title", using: :btree

  create_table "claims", force: :cascade do |t|
    t.datetime "completed_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "patient_ssn"
    t.string   "file_number"
    t.string   "first_name"
    t.string   "middle_name"
    t.string   "last_name"
    t.date     "date_of_birth"
    t.string   "facility_name"
    t.string   "facility_number"
    t.text     "exam_request_data"
    t.string   "vbms_claim_id"
    t.date     "claim_date"
    t.string   "email"
    t.string   "phone_number"
    t.string   "benefit_type"
    t.string   "label"
    t.string   "end_product_code"
    t.string   "edipi"
    t.string   "participant_id"
    t.string   "gender"
    t.string   "vista_ien"
    t.string   "alternate_phone"
    t.string   "integration_control_number"
    t.string   "poa_vso_name"
    t.string   "poa_vso_number"
    t.integer  "regional_office_id"
  end

  create_table "clarification_details", force: :cascade do |t|
    t.string   "event_id"
    t.integer  "contention_id"
    t.string   "clarification_type"
    t.text     "text"
    t.datetime "created_at",         null: false
    t.datetime "updated_at",         null: false
  end

  add_index "clarification_details", ["contention_id"], name: "index_clarification_details_on_contention_id", using: :btree

  create_table "clarification_types", force: :cascade do |t|
    t.string   "name"
    t.string   "code"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "clinics", force: :cascade do |t|
    t.integer  "site_id"
    t.integer  "clinic_id"
    t.string   "name"
    t.datetime "deleted_at"
  end

  add_index "clinics", ["clinic_id"], name: "index_clinics_on_clinic_id", unique: true, using: :btree
  add_index "clinics", ["deleted_at"], name: "index_clinics_on_deleted_at", using: :btree

  create_table "consultation_orders", force: :cascade do |t|
    t.string   "sequence",   null: false
    t.string   "title",      null: false
    t.datetime "deleted_at"
  end

  add_index "consultation_orders", ["deleted_at"], name: "index_consultation_orders_on_deleted_at", using: :btree
  add_index "consultation_orders", ["sequence"], name: "index_consultation_orders_on_sequence", using: :btree
  add_index "consultation_orders", ["title"], name: "index_consultation_orders_on_title", using: :btree

  create_table "consultation_statuses", force: :cascade do |t|
    t.string   "sequence",   null: false
    t.string   "title",      null: false
    t.datetime "deleted_at"
  end

  add_index "consultation_statuses", ["deleted_at"], name: "index_consultation_statuses_on_deleted_at", using: :btree
  add_index "consultation_statuses", ["sequence"], name: "index_consultation_statuses_on_sequence", using: :btree
  add_index "consultation_statuses", ["title"], name: "index_consultation_statuses_on_title", using: :btree

  create_table "consultation_types", force: :cascade do |t|
    t.string   "sequence",   null: false
    t.string   "title",      null: false
    t.datetime "deleted_at"
  end

  add_index "consultation_types", ["deleted_at"], name: "index_consultation_types_on_deleted_at", using: :btree
  add_index "consultation_types", ["sequence"], name: "index_consultation_types_on_sequence", using: :btree
  add_index "consultation_types", ["title"], name: "index_consultation_types_on_title", using: :btree

  create_table "consultations", force: :cascade do |t|
    t.string   "consultation_number",                 null: false
    t.integer  "ordering_provider_id"
    t.datetime "valid_from"
    t.datetime "valid_to"
    t.json     "content"
    t.datetime "created_at",                          null: false
    t.datetime "updated_at",                          null: false
    t.integer  "care_category_id"
    t.integer  "consultation_order_id"
    t.integer  "consultation_status_id"
    t.integer  "consultation_type_id"
    t.string   "veteran_ssn"
    t.string   "veteran_first_name"
    t.string   "veteran_middle_name"
    t.string   "veteran_last_name"
    t.string   "consultation_title"
    t.string   "veteran_dob"
    t.text     "consultation_text"
    t.string   "via_created_date"
    t.string   "veteran_other_health_insurance_name"
    t.string   "veteran_mpi_pid"
    t.string   "veteran_local_pid"
  end

  add_index "consultations", ["care_category_id"], name: "index_consultations_on_care_category_id", using: :btree
  add_index "consultations", ["consultation_number"], name: "index_consultations_on_consultation_number", unique: true, using: :btree
  add_index "consultations", ["consultation_order_id"], name: "index_consultations_on_consultation_order_id", using: :btree
  add_index "consultations", ["consultation_status_id"], name: "index_consultations_on_consultation_status_id", using: :btree
  add_index "consultations", ["consultation_type_id"], name: "index_consultations_on_consultation_type_id", using: :btree
  add_index "consultations", ["ordering_provider_id"], name: "index_consultations_on_ordering_provider_id", using: :btree

  create_table "contention_details", force: :cascade do |t|
    t.integer  "contention_id"
    t.text     "description"
    t.boolean  "active"
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
    t.string   "name"
    t.string   "event_id"
  end

  add_index "contention_details", ["contention_id"], name: "index_contention_details_on_contention_id", using: :btree

  create_table "contention_objects", force: :cascade do |t|
    t.text     "xml"
    t.string   "exam_related_contention_id"
    t.boolean  "active"
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
  end

  create_table "contentions", force: :cascade do |t|
    t.integer  "claim_id"
    t.datetime "resolved_at"
    t.string   "vba_diagnostic_code"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "name"
    t.text     "history"
    t.boolean  "no_diagnosis"
    t.boolean  "claim_folder_reviewed"
    t.boolean  "reviewed_military_service_treatment_records"
    t.boolean  "reviewed_military_service_personnel_records"
    t.boolean  "reviewed_military_enlistment_examination"
    t.boolean  "reviewed_military_separation_examination"
    t.boolean  "reviewed_military_post_deployment_questionnaire"
    t.boolean  "reviewed_dod_form_214_separation_documents"
    t.boolean  "reviewed_vha_treatment_records"
    t.boolean  "reviewed_civilian_medical_records"
    t.boolean  "reviewed_interviews_with_collateral_witnesses"
    t.datetime "reviewed_at"
    t.integer  "reviewed_by"
    t.integer  "assigner_id"
    t.boolean  "reviewed_not_indicated"
    t.string   "exam_related_contention_id"
    t.boolean  "clarification_requested"
    t.boolean  "is_contention_cancelled"
    t.text     "reason_for_cancellation"
    t.text     "cancellation_details"
    t.string   "identifier"
    t.boolean  "insufficient",                                    default: false
    t.string   "previously_worked_contention_id"
    t.integer  "exam_request_id"
  end

  add_index "contentions", ["assigner_id"], name: "index_contentions_on_assigner_id", using: :btree
  add_index "contentions", ["claim_id"], name: "index_contentions_on_claim_id", using: :btree
  add_index "contentions", ["reviewed_by"], name: "index_contentions_on_reviewed_by", using: :btree

  create_table "contentions_dbq_informations", force: :cascade do |t|
    t.integer "contention_id",      null: false
    t.integer "dbq_information_id", null: false
    t.integer "position"
  end

  add_index "contentions_dbq_informations", ["contention_id", "dbq_information_id"], name: "idx_contention_dbq_info", using: :btree

  create_table "contentions_evaluations", id: false, force: :cascade do |t|
    t.integer "contention_id"
    t.integer "evaluation_id"
  end

  add_index "contentions_evaluations", ["contention_id"], name: "index_contentions_evaluations_on_contention_id", using: :btree
  add_index "contentions_evaluations", ["evaluation_id"], name: "index_contentions_evaluations_on_evaluation_id", using: :btree

  create_table "contentions_examinations", id: false, force: :cascade do |t|
    t.integer "contention_id"
    t.integer "examination_id"
  end

  add_index "contentions_examinations", ["contention_id"], name: "index_contentions_examinations_on_contention_id", using: :btree
  add_index "contentions_examinations", ["examination_id"], name: "index_contentions_examinations_on_examination_id", using: :btree

  create_table "dashboards", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "dbq_informations", force: :cascade do |t|
    t.string   "identifier"
    t.string   "title"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "delayed_jobs", force: :cascade do |t|
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

  create_table "diagnoses", force: :cascade do |t|
    t.string   "name"
    t.string   "label"
    t.string   "code"
    t.integer  "diagnosis_modifier_id"
    t.datetime "created_at",                        null: false
    t.datetime "updated_at",                        null: false
    t.integer  "minor_system_id"
    t.integer  "position"
    t.integer  "format_type",           default: 0
  end

  add_index "diagnoses", ["minor_system_id"], name: "index_diagnoses_on_minor_system_id", using: :btree

  create_table "diagnoses_dbq_informations", force: :cascade do |t|
    t.integer "diagnosis_id",       null: false
    t.integer "dbq_information_id", null: false
    t.integer "position"
  end

  add_index "diagnoses_dbq_informations", ["diagnosis_id", "dbq_information_id"], name: "idx_diagnosis_dbq_info", using: :btree

  create_table "diagnosis_codes", force: :cascade do |t|
    t.string   "version_code", null: false
    t.string   "description",  null: false
    t.datetime "deleted_at"
  end

  add_index "diagnosis_codes", ["deleted_at"], name: "index_diagnosis_codes_on_deleted_at", using: :btree
  add_index "diagnosis_codes", ["version_code"], name: "index_diagnosis_codes_on_version_code", using: :btree

  create_table "diagnosis_modifiers", force: :cascade do |t|
    t.string   "name"
    t.string   "label"
    t.string   "mod_type"
    t.string   "list_values", default: [],              array: true
    t.datetime "created_at",               null: false
    t.datetime "updated_at",               null: false
  end

  create_table "dm_assignments", force: :cascade do |t|
    t.string   "name"
    t.string   "label"
    t.integer  "diagnosis_id"
    t.integer  "diagnosis_modifier_id"
    t.datetime "created_at",                            null: false
    t.datetime "updated_at",                            null: false
    t.string   "exam_response_fields"
    t.boolean  "negative_show",         default: false, null: false
    t.integer  "position"
  end

  add_index "dm_assignments", ["diagnosis_id"], name: "index_dm_assignments_on_diagnosis_id", using: :btree
  add_index "dm_assignments", ["diagnosis_modifier_id"], name: "index_dm_assignments_on_diagnosis_modifier_id", using: :btree

  create_table "evaluation_logs", force: :cascade do |t|
    t.integer  "evaluation_id"
    t.text     "response_body"
    t.text     "message"
    t.text     "submitted_data"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "evaluation_specs", force: :cascade do |t|
    t.text     "title"
    t.text     "version"
    t.text     "spec"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "body_system"
    t.string   "evaluation_builder_title"
    t.string   "dependent"
    t.string   "spec_id"
    t.boolean  "active",                   default: true
  end

  add_index "evaluation_specs", ["title"], name: "index_evaluation_specs_on_title", using: :btree

  create_table "evaluation_templates", force: :cascade do |t|
    t.string   "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string   "label"
  end

  add_index "evaluation_templates", ["name"], name: "index_evaluation_templates_on_name", unique: true, using: :btree

  create_table "evaluations", force: :cascade do |t|
    t.integer  "evaluation_spec_id"
    t.json     "doc"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "claim_id"
    t.datetime "completed_at"
    t.integer  "primary_evaluation_id"
    t.string   "guid"
    t.datetime "reviewed_at"
    t.string   "vha_user_vista_access_code"
    t.string   "vha_user_vista_verify_code"
    t.string   "vha_user_electronic_signature"
    t.integer  "user_id"
    t.integer  "assigner_id"
    t.integer  "examination_id"
  end

  add_index "evaluations", ["assigner_id"], name: "index_evaluations_on_assigner_id", using: :btree
  add_index "evaluations", ["claim_id", "user_id"], name: "index_evaluations_on_claim_id_and_user_id", using: :btree
  add_index "evaluations", ["claim_id"], name: "index_evaluations_on_claim_id", using: :btree
  add_index "evaluations", ["evaluation_spec_id"], name: "index_evaluations_on_evaluation_spec_id", using: :btree
  add_index "evaluations", ["examination_id"], name: "index_evaluations_on_examination_id", using: :btree
  add_index "evaluations", ["primary_evaluation_id"], name: "index_evaluations_on_primary_evaluation_id", using: :btree
  add_index "evaluations", ["user_id"], name: "index_evaluations_on_user_id", using: :btree

  create_table "exam_management_notifications", force: :cascade do |t|
    t.text     "xml"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "exam_prioritization_special_issues", force: :cascade do |t|
    t.text    "special_issue"
    t.integer "contention_id"
  end

  add_index "exam_prioritization_special_issues", ["contention_id"], name: "index_exam_prioritization_special_issues_on_contention_id", using: :btree

  create_table "exam_request_histories", force: :cascade do |t|
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
    t.integer  "exam_request_id"
    t.string   "notes"
  end

  create_table "exam_request_processors", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "exam_request_states", force: :cascade do |t|
    t.string   "name"
    t.string   "code"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "exam_requesters", force: :cascade do |t|
    t.string  "first_name"
    t.string  "last_name"
    t.string  "email_address"
    t.integer "primary_phone"
    t.string  "organization"
  end

  create_table "exam_requests", force: :cascade do |t|
    t.text     "xml"
    t.integer  "claim_id"
    t.text     "error_hash"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "site_id"
    t.string   "identifier"
    t.integer  "exam_request_status_id"
    t.integer  "exam_request_state_id"
    t.text     "cancellation_reason"
    t.boolean  "cancellation_acknowledged"
    t.integer  "exam_requester_id"
    t.datetime "request_date"
    t.string   "request_id"
    t.string   "special_issues"
    t.string   "participating_system_name"
  end

  add_index "exam_requests", ["claim_id"], name: "index_exam_requests_on_claim_id", using: :btree
  add_index "exam_requests", ["exam_request_state_id"], name: "index_exam_requests_on_exam_request_state_id", using: :btree
  add_index "exam_requests", ["exam_requester_id"], name: "index_exam_requests_on_exam_requester_id", using: :btree
  add_index "exam_requests", ["site_id"], name: "index_exam_requests_on_site_id", using: :btree

  create_table "examination_histories", force: :cascade do |t|
    t.integer  "examination_id"
    t.string   "notes"
    t.datetime "created_at",     null: false
    t.datetime "updated_at",     null: false
  end

  create_table "examination_notes", force: :cascade do |t|
    t.integer  "examination_id"
    t.integer  "from_id"
    t.integer  "to_id"
    t.text     "note"
    t.string   "type"
    t.datetime "created_at",     null: false
    t.datetime "updated_at",     null: false
  end

  add_index "examination_notes", ["examination_id"], name: "index_examination_notes_on_examination_id", using: :btree

  create_table "examination_review_questionnaires", force: :cascade do |t|
    t.boolean  "claim_folder_reviewed"
    t.boolean  "reviewed_not_indicated"
    t.boolean  "reviewed_military_service_treatment_records"
    t.boolean  "reviewed_military_service_personnel_records"
    t.boolean  "reviewed_military_enlistment_examination"
    t.boolean  "reviewed_military_separation_examination"
    t.boolean  "reviewed_military_post_deployment_questionnaire"
    t.boolean  "reviewed_dod_form_214_separation_documents"
    t.boolean  "reviewed_vha_treatment_records"
    t.boolean  "reviewed_civilian_medical_records"
    t.boolean  "reviewed_interviews_with_collateral_witnesses"
    t.boolean  "not_requested"
    t.boolean  "va_claims_file"
    t.boolean  "va_e_folder"
    t.boolean  "cprs"
    t.boolean  "no_records_were_reviewed"
    t.boolean  "other"
    t.text     "other_text"
    t.boolean  "evidence_comments"
    t.text     "evidence_comments_text"
    t.integer  "examination_id"
    t.datetime "created_at",                                      null: false
    t.datetime "updated_at",                                      null: false
  end

  create_table "examination_schedules", force: :cascade do |t|
    t.integer  "examination_id"
    t.text     "reschedule_reason"
    t.boolean  "active"
    t.datetime "exam_date_time"
    t.datetime "created_at",           null: false
    t.datetime "updated_at",           null: false
    t.string   "cancel_code"
    t.string   "cancel_reason"
    t.integer  "clinic_id"
    t.string   "appt_address_1"
    t.string   "appt_address_2"
    t.string   "appt_address_city"
    t.string   "appt_address_state"
    t.string   "appt_address_zipcode"
  end

  add_index "examination_schedules", ["examination_id"], name: "index_examination_schedules_on_examination_id", using: :btree

  create_table "examination_states", force: :cascade do |t|
    t.string "name"
    t.string "code"
  end

  create_table "examinations", force: :cascade do |t|
    t.string   "title"
    t.datetime "exam_date"
    t.integer  "state"
    t.integer  "exam_id"
    t.integer  "clinician"
    t.datetime "created_at",                                null: false
    t.datetime "updated_at",                                null: false
    t.integer  "site_id"
    t.integer  "examination_state_id"
    t.boolean  "active"
    t.string   "examfile"
    t.integer  "exam_request_id"
    t.string   "purpose"
    t.integer  "evaluation_id"
    t.datetime "examination_state_start_date"
    t.string   "examfiles",                    default: [],              array: true
    t.integer  "claim_id"
    t.text     "cancellation_reason"
    t.string   "identifier"
    t.boolean  "acknowledged"
    t.boolean  "clinician_acknowledged"
    t.text     "interview"
    t.text     "plan"
    t.datetime "reviewed_at"
    t.integer  "reviewed_by"
  end

  add_index "examinations", ["claim_id"], name: "index_examinations_on_claim_id", using: :btree
  add_index "examinations", ["evaluation_id"], name: "index_examinations_on_evaluation_id", using: :btree
  add_index "examinations", ["exam_id"], name: "index_examinations_on_exam_id", unique: true, using: :btree
  add_index "examinations", ["exam_request_id"], name: "index_examinations_on_exam_request_id", using: :btree
  add_index "examinations", ["examination_state_id"], name: "index_examinations_on_examination_state_id", using: :btree
  add_index "examinations", ["site_id"], name: "index_examinations_on_site_id", using: :btree

  create_table "facilities", force: :cascade do |t|
    t.string  "name"
    t.json    "content"
    t.integer "visn_id"
  end

  add_index "facilities", ["name"], name: "index_facilities_on_name", unique: true, using: :btree
  add_index "facilities", ["visn_id"], name: "index_facilities_on_visn_id", using: :btree

  create_table "general_questions", force: :cascade do |t|
    t.string   "name"
    t.string   "label"
    t.integer  "diagnosis_modifier_id"
    t.integer  "minor_system_id"
    t.datetime "created_at",                        null: false
    t.datetime "updated_at",                        null: false
    t.integer  "position"
    t.integer  "question_type",         default: 0
  end

  add_index "general_questions", ["minor_system_id"], name: "index_general_questions_on_minor_system_id", using: :btree

  create_table "general_questions_dbq_informations", force: :cascade do |t|
    t.integer "general_question_id", null: false
    t.integer "dbq_information_id",  null: false
    t.integer "position"
  end

  add_index "general_questions_dbq_informations", ["general_question_id", "dbq_information_id"], name: "idx_general_question_dbq_info", using: :btree

  create_table "html_repositories", force: :cascade do |t|
    t.string   "name"
    t.text     "html"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "html_repositories", ["name"], name: "index_html_repositories_on_name", unique: true, using: :btree

  create_table "major_systems", force: :cascade do |t|
    t.string   "name"
    t.string   "label"
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
    t.integer  "evaluation_template_id"
    t.integer  "position"
  end

  add_index "major_systems", ["evaluation_template_id"], name: "index_major_systems_on_evaluation_template_id", using: :btree

  create_table "medical_specialties", force: :cascade do |t|
    t.string   "sequence",   null: false
    t.string   "title",      null: false
    t.datetime "deleted_at"
  end

  add_index "medical_specialties", ["deleted_at"], name: "index_medical_specialties_on_deleted_at", using: :btree
  add_index "medical_specialties", ["sequence"], name: "index_medical_specialties_on_sequence", using: :btree
  add_index "medical_specialties", ["title"], name: "index_medical_specialties_on_title", using: :btree

  create_table "medical_specialties_providers", id: false, force: :cascade do |t|
    t.integer "medical_specialty_id"
    t.integer "provider_id"
  end

  add_index "medical_specialties_providers", ["medical_specialty_id"], name: "index_medical_specialties_providers_on_medical_specialty_id", using: :btree
  add_index "medical_specialties_providers", ["provider_id"], name: "index_medical_specialties_providers_on_provider_id", using: :btree

  create_table "minor_systems", force: :cascade do |t|
    t.string   "name"
    t.string   "label"
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
    t.integer  "major_system_id"
    t.integer  "position"
  end

  add_index "minor_systems", ["major_system_id"], name: "index_minor_systems_on_major_system_id", using: :btree

  create_table "notification_logs", force: :cascade do |t|
    t.integer  "claim_id"
    t.text     "submitted_xml_data"
    t.string   "event_id"
    t.text     "response_body"
    t.text     "message"
    t.datetime "created_at",         null: false
    t.datetime "updated_at",         null: false
    t.string   "notification_type"
  end

  create_table "notifications", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "other_health_insurances", force: :cascade do |t|
    t.string   "sequence",   null: false
    t.string   "title",      null: false
    t.datetime "deleted_at"
  end

  add_index "other_health_insurances", ["deleted_at"], name: "index_other_health_insurances_on_deleted_at", using: :btree
  add_index "other_health_insurances", ["sequence"], name: "index_other_health_insurances_on_sequence", using: :btree
  add_index "other_health_insurances", ["title"], name: "index_other_health_insurances_on_title", using: :btree

  create_table "pointless_feedback_messages", force: :cascade do |t|
    t.string   "name"
    t.string   "email_address"
    t.string   "topic"
    t.text     "description"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "preferred_geo_locations", force: :cascade do |t|
    t.string   "address_1"
    t.string   "address_2"
    t.string   "address_3"
    t.string   "city"
    t.string   "zip"
    t.string   "state"
    t.integer  "claim_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "preferred_geo_locations", ["claim_id"], name: "index_preferred_geo_locations_on_claim_id", using: :btree

  create_table "providers", force: :cascade do |t|
    t.string   "npi",            null: false
    t.string   "name",           null: false
    t.string   "physician_name", null: false
    t.json     "content"
    t.datetime "created_at",     null: false
    t.datetime "updated_at",     null: false
    t.integer  "facility_id"
  end

  add_index "providers", ["facility_id"], name: "index_providers_on_facility_id", using: :btree
  add_index "providers", ["name"], name: "index_providers_on_name", using: :btree
  add_index "providers", ["npi"], name: "index_providers_on_npi", unique: true, using: :btree

  create_table "providers_users", force: :cascade do |t|
    t.integer "provider_id"
    t.integer "user_id"
  end

  add_index "providers_users", ["provider_id", "user_id"], name: "index_providers_users_on_provider_id_and_user_id", unique: true, using: :btree
  add_index "providers_users", ["provider_id"], name: "index_providers_users_on_provider_id", using: :btree
  add_index "providers_users", ["user_id"], name: "index_providers_users_on_user_id", using: :btree

  create_table "qm_assignments", force: :cascade do |t|
    t.string   "name"
    t.string   "label"
    t.string   "exam_response_fields"
    t.integer  "general_question_id"
    t.integer  "question_modifier_id"
    t.datetime "created_at",                           null: false
    t.datetime "updated_at",                           null: false
    t.boolean  "negative_show",        default: false, null: false
    t.integer  "position"
  end

  add_index "qm_assignments", ["general_question_id"], name: "index_qm_assignments_on_general_question_id", using: :btree
  add_index "qm_assignments", ["question_modifier_id"], name: "index_qm_assignments_on_question_modifier_id", using: :btree

  create_table "question_modifiers", force: :cascade do |t|
    t.string   "name"
    t.string   "label"
    t.string   "mod_type"
    t.string   "list_values", default: [],              array: true
    t.text     "html"
    t.datetime "created_at",               null: false
    t.datetime "updated_at",               null: false
  end

  create_table "referral_appointments", force: :cascade do |t|
    t.json     "content"
    t.datetime "created_at",       null: false
    t.datetime "updated_at",       null: false
    t.integer  "referral_id"
    t.datetime "appointment_time"
    t.datetime "added_to_cprs_at"
    t.integer  "added_to_cprs_id"
  end

  add_index "referral_appointments", ["added_to_cprs_id"], name: "index_referral_appointments_on_added_to_cprs_id", using: :btree
  add_index "referral_appointments", ["referral_id"], name: "index_referral_appointments_on_referral_id", using: :btree

  create_table "referral_approvals", force: :cascade do |t|
    t.json     "content"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
    t.integer  "referral_id"
  end

  add_index "referral_approvals", ["referral_id"], name: "index_referral_approvals_on_referral_id", using: :btree

  create_table "referral_document_types", force: :cascade do |t|
    t.string   "sequence",   null: false
    t.string   "title",      null: false
    t.datetime "deleted_at"
  end

  add_index "referral_document_types", ["deleted_at"], name: "index_referral_document_types_on_deleted_at", using: :btree
  add_index "referral_document_types", ["sequence"], name: "index_referral_document_types_on_sequence", using: :btree
  add_index "referral_document_types", ["title"], name: "index_referral_document_types_on_title", using: :btree

  create_table "referral_documents", force: :cascade do |t|
    t.integer  "referral_document_type_id"
    t.integer  "uploader_id"
    t.integer  "approver_id"
    t.datetime "approved_at"
    t.json     "content"
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
    t.integer  "referral_id"
  end

  add_index "referral_documents", ["approver_id"], name: "index_referral_documents_on_approver_id", using: :btree
  add_index "referral_documents", ["referral_document_type_id"], name: "index_referral_documents_on_referral_document_type_id", using: :btree
  add_index "referral_documents", ["referral_id"], name: "index_referral_documents_on_referral_id", using: :btree
  add_index "referral_documents", ["uploader_id"], name: "index_referral_documents_on_uploader_id", using: :btree

  create_table "referral_notes", force: :cascade do |t|
    t.json     "content"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
    t.integer  "referral_id"
  end

  add_index "referral_notes", ["referral_id"], name: "index_referral_notes_on_referral_id", using: :btree

  create_table "referral_reasons", force: :cascade do |t|
    t.string   "sequence",   null: false
    t.string   "title",      null: false
    t.datetime "deleted_at"
  end

  add_index "referral_reasons", ["deleted_at"], name: "index_referral_reasons_on_deleted_at", using: :btree
  add_index "referral_reasons", ["sequence"], name: "index_referral_reasons_on_sequence", using: :btree
  add_index "referral_reasons", ["title"], name: "index_referral_reasons_on_title", using: :btree

  create_table "referral_statuses", force: :cascade do |t|
    t.string "name"
    t.string "code"
    t.string "referral_queue"
    t.string "filterable_by_roles"
    t.string "update_description"
  end

  add_index "referral_statuses", ["code"], name: "index_referral_statuses_on_code", unique: true, using: :btree
  add_index "referral_statuses", ["name"], name: "index_referral_statuses_on_name", unique: true, using: :btree

  create_table "referral_types", force: :cascade do |t|
    t.string   "sequence",   null: false
    t.string   "title",      null: false
    t.datetime "deleted_at"
  end

  add_index "referral_types", ["deleted_at"], name: "index_referral_types_on_deleted_at", using: :btree
  add_index "referral_types", ["sequence"], name: "index_referral_types_on_sequence", using: :btree
  add_index "referral_types", ["title"], name: "index_referral_types_on_title", using: :btree

  create_table "referrals", force: :cascade do |t|
    t.integer  "coordinator_id",       null: false
    t.string   "referral_number",      null: false
    t.string   "authorization_number", null: false
    t.json     "content"
    t.datetime "created_at",           null: false
    t.datetime "updated_at",           null: false
    t.integer  "consultation_id"
    t.integer  "referral_status_id"
    t.integer  "referral_type_id"
    t.integer  "referral_reason_id"
    t.integer  "provider_id"
  end

  add_index "referrals", ["authorization_number"], name: "index_referrals_on_authorization_number", unique: true, using: :btree
  add_index "referrals", ["consultation_id"], name: "index_referrals_on_consultation_id", using: :btree
  add_index "referrals", ["coordinator_id"], name: "index_referrals_on_coordinator_id", using: :btree
  add_index "referrals", ["provider_id"], name: "index_referrals_on_provider_id", using: :btree
  add_index "referrals", ["referral_number"], name: "index_referrals_on_referral_number", unique: true, using: :btree
  add_index "referrals", ["referral_reason_id"], name: "index_referrals_on_referral_reason_id", using: :btree
  add_index "referrals", ["referral_status_id"], name: "index_referrals_on_referral_status_id", using: :btree
  add_index "referrals", ["referral_type_id"], name: "index_referrals_on_referral_type_id", using: :btree

  create_table "regional_offices", force: :cascade do |t|
    t.string   "station_number"
    t.text     "physical_address"
    t.text     "mailing_address"
    t.datetime "created_at",       null: false
    t.datetime "updated_at",       null: false
  end

  create_table "rejections", force: :cascade do |t|
    t.string   "reason"
    t.integer  "contention_id"
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
  end

  add_index "rejections", ["contention_id"], name: "index_rejections_on_contention_id", using: :btree

  create_table "request_objects", force: :cascade do |t|
    t.string   "request_type"
    t.string   "event_id"
    t.string   "claim_id"
    t.boolean  "active"
    t.text     "xml"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
  end

  create_table "rework_reason_free_texts", force: :cascade do |t|
    t.text     "reason"
    t.integer  "contention_id"
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
  end

  add_index "rework_reason_free_texts", ["contention_id"], name: "index_rework_reason_free_texts_on_contention_id", using: :btree

  create_table "rework_reasons", force: :cascade do |t|
    t.text     "reason"
    t.integer  "contention_id"
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
  end

  add_index "rework_reasons", ["contention_id"], name: "index_rework_reasons_on_contention_id", using: :btree

  create_table "service_periods", force: :cascade do |t|
    t.date     "entry_on_duty"
    t.date     "service_end_date"
    t.string   "branch_of_service"
    t.text     "eras"
    t.integer  "claim_id"
    t.datetime "created_at",        null: false
    t.datetime "updated_at",        null: false
  end

  add_index "service_periods", ["claim_id"], name: "index_service_periods_on_claim_id", using: :btree

  create_table "site_role_sets", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "site_id"
    t.boolean  "admin",           default: false, null: false
    t.boolean  "triage",          default: false, null: false
    t.boolean  "scheduling",      default: false, null: false
    t.boolean  "clinician",       default: false, null: false
    t.boolean  "super_clinician", default: false, null: false
    t.boolean  "qa",              default: false, null: false
    t.datetime "created_at",                      null: false
    t.datetime "updated_at",                      null: false
    t.boolean  "vha_cc",          default: false, null: false
    t.boolean  "non_vha",         default: false, null: false
  end

  add_index "site_role_sets", ["site_id"], name: "index_site_role_sets_on_site_id", using: :btree
  add_index "site_role_sets", ["user_id"], name: "index_site_role_sets_on_user_id", using: :btree

  create_table "sites", force: :cascade do |t|
    t.string   "name"
    t.string   "address"
    t.string   "city"
    t.string   "state"
    t.string   "country"
    t.datetime "created_at",                   null: false
    t.datetime "updated_at",                   null: false
    t.string   "access_requests", default: [],              array: true
    t.string   "role_requests",   default: [],              array: true
    t.string   "site_station_number"
    t.string   "zip_code"
    t.datetime "deleted_at"
  end

  add_index "sites", ["deleted_at"], name: "index_sites_on_deleted_at", using: :btree

  create_table "supervised_clinicians", force: :cascade do |t|
    t.integer "user_id"
    t.integer "supervised_id"
  end

  add_index "supervised_clinicians", ["supervised_id", "user_id"], name: "index_supervised_clinicians_on_supervised_id_and_user_id", unique: true, using: :btree
  add_index "supervised_clinicians", ["user_id", "supervised_id"], name: "index_supervised_clinicians_on_user_id_and_supervised_id", unique: true, using: :btree

  create_table "supervising_clinicians", force: :cascade do |t|
    t.integer "user_id"
    t.integer "supervisor_id"
  end

  add_index "supervising_clinicians", ["supervisor_id", "user_id"], name: "index_supervising_clinicians_on_supervisor_id_and_user_id", unique: true, using: :btree
  add_index "supervising_clinicians", ["user_id", "supervisor_id"], name: "index_supervising_clinicians_on_user_id_and_supervisor_id", unique: true, using: :btree

  create_table "support_request_categories", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string   "name",       null: false
  end

  create_table "support_request_organizations", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string   "short_name", null: false
    t.string   "long_name",  null: false
  end

  create_table "support_requests", force: :cascade do |t|
    t.datetime "created_at",            null: false
    t.datetime "updated_at",            null: false
    t.string   "ticket_number",         null: false
    t.string   "first_name",            null: false
    t.string   "last_name",             null: false
    t.string   "customer_phone",        null: false
    t.string   "customer_email",        null: false
    t.string   "customer_organization", null: false
    t.string   "customer_site",         null: false
    t.string   "issue_description",     null: false
    t.integer  "severity"
    t.string   "details"
  end

  create_table "symp_diag_relations", force: :cascade do |t|
    t.integer  "symptom_id"
    t.integer  "diagnosis_id"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
  end

  add_index "symp_diag_relations", ["diagnosis_id"], name: "index_symp_diag_relations_on_diagnosis_id", using: :btree
  add_index "symp_diag_relations", ["symptom_id", "diagnosis_id"], name: "index_symp_diag_relations_on_symptom_id_and_diagnosis_id", unique: true, using: :btree
  add_index "symp_diag_relations", ["symptom_id"], name: "index_symp_diag_relations_on_symptom_id", using: :btree

  create_table "symptoms", force: :cascade do |t|
    t.string   "name"
    t.string   "label"
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
    t.integer  "minor_system_id"
    t.integer  "position"
  end

  add_index "symptoms", ["minor_system_id"], name: "index_symptoms_on_minor_system_id", using: :btree

  create_table "symptoms_dbq_informations", force: :cascade do |t|
    t.integer "symptom_id",         null: false
    t.integer "dbq_information_id", null: false
    t.integer "position"
  end

  add_index "symptoms_dbq_informations", ["symptom_id", "dbq_information_id"], name: "idx_symptom_dbq_info", using: :btree

  create_table "user_preferences", force: :cascade do |t|
    t.json     "consultation_filter", default: {}
    t.json     "referral_filter",     default: {}
    t.integer  "user_id"
    t.datetime "created_at",                       null: false
    t.datetime "updated_at",                       null: false
    t.string   "time_zone"
    t.string   "vista_duz"
    t.string   "vista_user_name"
    t.string   "vista_site_id"
  end

  add_index "user_preferences", ["user_id"], name: "index_user_preferences_on_user_id", using: :btree

  create_table "users", force: :cascade do |t|
    t.string   "email",                  default: "",     null: false
    t.string   "encrypted_password",     default: "",     null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          default: 0,      null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.inet     "current_sign_in_ip"
    t.inet     "last_sign_in_ip"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "roles"
    t.string   "first_name"
    t.string   "last_name"
    t.boolean  "is_under_review",        default: true
    t.integer  "failed_attempts",        default: 0
    t.string   "unlock_token"
    t.datetime "locked_at"
    t.string   "provider"
    t.string   "uid"
    t.string   "authorization_state",    default: "none"
    t.string   "action_token"
  end

  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree

  create_table "vbms_r_fact_groups", force: :cascade do |t|
    t.string   "name"
    t.string   "namespace"
    t.string   "fact_block_tag_name"
    t.string   "diagnosis_tag_name"
    t.string   "symptom_tag_name"
    t.string   "document_title"
    t.datetime "created_at",          null: false
    t.datetime "updated_at",          null: false
    t.text     "diagnosis_info"
    t.text     "symptom_info"
    t.string   "additional_fields"
    t.string   "text"
  end

  create_table "veterans", force: :cascade do |t|
    t.string   "ssn",                         limit: 10, null: false
    t.string   "first_name"
    t.string   "middle_name"
    t.string   "last_name"
    t.string   "other_health_insurance_name"
    t.json     "content"
    t.datetime "created_at",                             null: false
    t.datetime "updated_at",                             null: false
    t.integer  "other_health_insurance_id"
  end

  add_index "veterans", ["first_name"], name: "index_veterans_on_first_name", using: :btree
  add_index "veterans", ["last_name"], name: "index_veterans_on_last_name", using: :btree
  add_index "veterans", ["other_health_insurance_id"], name: "index_veterans_on_other_health_insurance_id", using: :btree
  add_index "veterans", ["ssn"], name: "index_veterans_on_ssn", unique: true, using: :btree

  create_table "visns", force: :cascade do |t|
    t.string   "sequence"
    t.datetime "deleted_at"
    t.integer  "region"
    t.string   "name"
  end

  add_index "visns", ["deleted_at"], name: "index_visns_on_deleted_at", using: :btree
  add_index "visns", ["sequence"], name: "index_visns_on_sequence", using: :btree

  add_foreign_key "consultations", "care_categories"
  add_foreign_key "consultations", "consultation_orders"
  add_foreign_key "consultations", "consultation_statuses"
  add_foreign_key "consultations", "consultation_types"
  add_foreign_key "evaluations", "examinations"
  add_foreign_key "exam_prioritization_special_issues", "contentions"
  add_foreign_key "exam_requests", "exam_requesters"
  add_foreign_key "examinations", "evaluations"
  add_foreign_key "facilities", "visns"
  add_foreign_key "providers", "facilities"
  add_foreign_key "providers_users", "providers"
  add_foreign_key "providers_users", "users"
  add_foreign_key "referral_appointments", "referrals"
  add_foreign_key "referral_appointments", "users", column: "added_to_cprs_id"
  add_foreign_key "referral_approvals", "referrals"
  add_foreign_key "referral_documents", "referrals"
  add_foreign_key "referral_notes", "referrals"
  add_foreign_key "referrals", "consultations"
  add_foreign_key "referrals", "providers"
  add_foreign_key "referrals", "referral_reasons"
  add_foreign_key "referrals", "referral_statuses"
  add_foreign_key "referrals", "referral_types"
  add_foreign_key "rework_reason_free_texts", "contentions"
  add_foreign_key "rework_reasons", "contentions"
  add_foreign_key "user_preferences", "users"
  add_foreign_key "veterans", "other_health_insurances"
end
