# Data Dictionary

This report is auto-generated from the file 'db/schema.rb'

Report Date:    2017-10-27
Last Migration: 20171025230918



## Database Tables

| Table Name | Indexed By | Associated With |
| ---------- | ---------- | --------------- |
| alerts | N/A | N/A |
| appointment_objects | N/A | N/A |
| boilerplate_messages | N/A | N/A |
| boilerplate_messages_dbq_informations | boilerplate_message_id | N/A |
| care_categories | deleted_at, sequence, title | consultations |
| claims | N/A | N/A |
| clarification_details | contention_id | N/A |
| clarification_types | N/A | N/A |
| clinics | clinic_id, deleted_at | N/A |
| consultation_orders | deleted_at, sequence, title | consultations |
| consultation_statuses | deleted_at, sequence, title | consultations |
| consultation_types | deleted_at, sequence, title | consultations |
| consultations | care_category_id, consultation_number, consultation_order_id, consultation_status_id, consultation_type_id, ordering_provider_id | care_categories, consultation_orders, consultation_statuses, consultation_types, referrals |
| contention_details | contention_id | N/A |
| contention_objects | N/A | N/A |
| contentions | assigner_id, claim_id, reviewed_by | exam_prioritization_special_issues, rework_reason_free_texts, rework_reasons |
| contentions_dbq_informations | contention_id | N/A |
| contentions_evaluations | contention_id, evaluation_id | N/A |
| contentions_examinations | contention_id, examination_id | N/A |
| dashboards | N/A | N/A |
| dbq_informations | N/A | N/A |
| delayed_jobs | priority | N/A |
| diagnoses | minor_system_id | N/A |
| diagnoses_dbq_informations | diagnosis_id | N/A |
| diagnosis_codes | deleted_at, version_code | N/A |
| diagnosis_modifiers | N/A | N/A |
| dm_assignments | diagnosis_id, diagnosis_modifier_id | N/A |
| evaluation_logs | N/A | N/A |
| evaluation_specs | title | N/A |
| evaluation_templates | name | N/A |
| evaluations | assigner_id, claim_id, claim_id, evaluation_spec_id, examination_id, primary_evaluation_id, user_id | examinations, examinations |
| exam_management_notifications | N/A | N/A |
| exam_prioritization_special_issues | contention_id | contentions |
| exam_request_histories | N/A | N/A |
| exam_request_processors | N/A | N/A |
| exam_request_states | N/A | N/A |
| exam_requesters | N/A | exam_requests |
| exam_requests | claim_id, exam_request_state_id, exam_requester_id, site_id | exam_requesters |
| examination_histories | N/A | N/A |
| examination_notes | examination_id | N/A |
| examination_review_questionnaires | N/A | N/A |
| examination_schedules | examination_id | N/A |
| examination_states | N/A | N/A |
| examinations | claim_id, evaluation_id, exam_id, exam_request_id, examination_state_id, site_id | evaluations, evaluations |
| facilities | name, visn_id | visns, providers |
| general_questions | minor_system_id | N/A |
| general_questions_dbq_informations | general_question_id | N/A |
| html_repositories | name | N/A |
| major_systems | evaluation_template_id | N/A |
| medical_specialties | deleted_at, sequence, title | N/A |
| medical_specialties_providers | medical_specialty_id, provider_id | N/A |
| minor_systems | major_system_id | N/A |
| notification_logs | N/A | N/A |
| notifications | N/A | N/A |
| other_health_insurances | deleted_at, sequence, title | veterans |
| pointless_feedback_messages | N/A | N/A |
| preferred_geo_locations | claim_id | N/A |
| providers | facility_id, name, npi | facilities, providers_users, referrals |
| providers_users | provider_id, provider_id, user_id | providers, users |
| qm_assignments | general_question_id, question_modifier_id | N/A |
| question_modifiers | N/A | N/A |
| referral_appointments | added_to_cprs_id, referral_id | referrals, users |
| referral_approvals | referral_id | referrals |
| referral_document_types | deleted_at, sequence, title | N/A |
| referral_documents | approver_id, referral_document_type_id, referral_id, uploader_id | referrals |
| referral_notes | referral_id | referrals |
| referral_reasons | deleted_at, sequence, title | referrals |
| referral_statuses | code, name | referrals |
| referral_types | deleted_at, sequence, title | referrals |
| referrals | authorization_number, consultation_id, coordinator_id, provider_id, referral_number, referral_reason_id, referral_status_id, referral_type_id | referral_appointments, referral_approvals, referral_documents, referral_notes, consultations, providers, referral_reasons, referral_statuses, referral_types |
| regional_offices | N/A | N/A |
| rejections | contention_id | N/A |
| request_objects | N/A | N/A |
| rework_reason_free_texts | contention_id | contentions |
| rework_reasons | contention_id | contentions |
| service_periods | claim_id | N/A |
| site_role_sets | site_id, user_id | N/A |
| sites | deleted_at | N/A |
| supervised_clinicians | supervised_id, user_id | N/A |
| supervising_clinicians | supervisor_id, user_id | N/A |
| support_request_categories | N/A | N/A |
| support_request_organizations | N/A | N/A |
| support_requests | N/A | N/A |
| symp_diag_relations | diagnosis_id, symptom_id, symptom_id | N/A |
| symptoms | minor_system_id | N/A |
| symptoms_dbq_informations | symptom_id | N/A |
| user_preferences | user_id | users |
| users | email, reset_password_token | providers_users, referral_appointments, user_preferences |
| vbms_r_fact_groups | N/A | N/A |
| veterans | first_name, last_name, other_health_insurance_id, ssn | other_health_insurances |
| visns | deleted_at, sequence | facilities |




## Column Definitions

| Column Name | Table Name | Data Type | Qualifiers |
| ----------- | ---------- | --------- | ---------- |
| access_requests | sites | string | {:default=>[], :array=>true} |
| acknowledged | examinations | boolean |  |
| action_token | users | string |  |
| active | alerts | boolean | {:default=>true} |
| active | appointment_objects | boolean |  |
| active | contention_details | boolean |  |
| active | contention_objects | boolean |  |
| active | evaluation_specs | boolean | {:default=>true} |
| active | examination_schedules | boolean |  |
| active | examinations | boolean |  |
| active | request_objects | boolean |  |
| added_to_cprs_at | referral_appointments | datetime |  |
| added_to_cprs_id | referral_appointments | integer |  |
| additional_fields | vbms_r_fact_groups | string |  |
| address | sites | string |  |
| address_1 | preferred_geo_locations | string |  |
| address_2 | preferred_geo_locations | string |  |
| address_3 | preferred_geo_locations | string |  |
| admin | site_role_sets | boolean | {:default=>false, :null=>false} |
| alternate_phone | claims | string |  |
| appointment_time | referral_appointments | datetime |  |
| approved_at | referral_documents | datetime |  |
| approver_id | referral_documents | integer |  |
| appt_address_1 | examination_schedules | string |  |
| appt_address_2 | examination_schedules | string |  |
| appt_address_city | examination_schedules | string |  |
| appt_address_state | examination_schedules | string |  |
| appt_address_zipcode | examination_schedules | string |  |
| assigner_id | contentions | integer |  |
| assigner_id | evaluations | integer |  |
| attempts | delayed_jobs | integer | {:default=>0, :null=>false} |
| authorization_number | referrals | string | {:null=>false} |
| authorization_state | users | string | {:default=>"none"} |
| benefit_type | claims | string |  |
| body_system | evaluation_specs | string |  |
| boilerplate_message_id | boilerplate_messages_dbq_informations | integer | {:null=>false} |
| branch_of_service | service_periods | string |  |
| cancel_code | examination_schedules | string |  |
| cancel_reason | examination_schedules | string |  |
| cancellation_acknowledged | exam_requests | boolean |  |
| cancellation_details | contentions | text |  |
| cancellation_reason | exam_requests | text |  |
| cancellation_reason | examinations | text |  |
| care_category_id | consultations | integer |  |
| care_category_id | consultations | reference |  |
| city | preferred_geo_locations | string |  |
| city | sites | string |  |
| claim_date | claims | date |  |
| claim_folder_reviewed | contentions | boolean |  |
| claim_folder_reviewed | examination_review_questionnaires | boolean |  |
| claim_id | contentions | integer |  |
| claim_id | evaluations | integer |  |
| claim_id | exam_requests | integer |  |
| claim_id | examinations | integer |  |
| claim_id | notification_logs | integer |  |
| claim_id | preferred_geo_locations | integer |  |
| claim_id | request_objects | string |  |
| claim_id | service_periods | integer |  |
| clarification_requested | contentions | boolean |  |
| clarification_type | clarification_details | string |  |
| clinic_id | clinics | integer |  |
| clinic_id | examination_schedules | integer |  |
| clinician | examinations | integer |  |
| clinician | site_role_sets | boolean | {:default=>false, :null=>false} |
| clinician_acknowledged | examinations | boolean |  |
| code | clarification_types | string |  |
| code | diagnoses | string |  |
| code | exam_request_states | string |  |
| code | examination_states | string |  |
| code | referral_statuses | string |  |
| completed_at | claims | datetime |  |
| completed_at | evaluations | datetime |  |
| completed_by | alerts | integer |  |
| consultation_filter | user_preferences | json | {:default=>{}} |
| consultation_id | referrals | integer |  |
| consultation_id | referrals | reference |  |
| consultation_number | consultations | string | {:null=>false} |
| consultation_order_id | consultations | integer |  |
| consultation_order_id | consultations | reference |  |
| consultation_status_id | consultations | integer |  |
| consultation_status_id | consultations | reference |  |
| consultation_text | consultations | text |  |
| consultation_title | consultations | string |  |
| consultation_type_id | consultations | integer |  |
| consultation_type_id | consultations | reference |  |
| content | boilerplate_messages | string |  |
| content | consultations | json |  |
| content | facilities | json |  |
| content | providers | json |  |
| content | referral_appointments | json |  |
| content | referral_approvals | json |  |
| content | referral_documents | json |  |
| content | referral_notes | json |  |
| content | referrals | json |  |
| content | veterans | json |  |
| contention_id | appointment_objects | integer |  |
| contention_id | clarification_details | integer |  |
| contention_id | contention_details | integer |  |
| contention_id | contentions_dbq_informations | integer | {:null=>false} |
| contention_id | contentions_evaluations | integer |  |
| contention_id | contentions_examinations | integer |  |
| contention_id | exam_prioritization_special_issues | integer |  |
| contention_id | rejections | integer |  |
| contention_id | rework_reason_free_texts | integer |  |
| contention_id | rework_reasons | integer |  |
| contention_id | exam_prioritization_special_issues | reference |  |
| contention_id | rework_reason_free_texts | reference |  |
| contention_id | rework_reasons | reference |  |
| coordinator_id | referrals | integer | {:null=>false} |
| country | sites | string |  |
| cprs | examination_review_questionnaires | boolean |  |
| created_at | alerts | datetime | {:null=>false} |
| created_at | appointment_objects | datetime | {:null=>false} |
| created_at | boilerplate_messages | datetime | {:null=>false} |
| created_at | claims | datetime |  |
| created_at | clarification_details | datetime | {:null=>false} |
| created_at | clarification_types | datetime | {:null=>false} |
| created_at | consultations | datetime | {:null=>false} |
| created_at | contention_details | datetime | {:null=>false} |
| created_at | contention_objects | datetime | {:null=>false} |
| created_at | contentions | datetime |  |
| created_at | dashboards | datetime | {:null=>false} |
| created_at | dbq_informations | datetime | {:null=>false} |
| created_at | delayed_jobs | datetime |  |
| created_at | diagnoses | datetime | {:null=>false} |
| created_at | diagnosis_modifiers | datetime | {:null=>false} |
| created_at | dm_assignments | datetime | {:null=>false} |
| created_at | evaluation_logs | datetime |  |
| created_at | evaluation_specs | datetime |  |
| created_at | evaluation_templates | datetime | {:null=>false} |
| created_at | evaluations | datetime |  |
| created_at | exam_management_notifications | datetime | {:null=>false} |
| created_at | exam_request_histories | datetime | {:null=>false} |
| created_at | exam_request_processors | datetime | {:null=>false} |
| created_at | exam_request_states | datetime | {:null=>false} |
| created_at | exam_requests | datetime |  |
| created_at | examination_histories | datetime | {:null=>false} |
| created_at | examination_notes | datetime | {:null=>false} |
| created_at | examination_review_questionnaires | datetime | {:null=>false} |
| created_at | examination_schedules | datetime | {:null=>false} |
| created_at | examinations | datetime | {:null=>false} |
| created_at | general_questions | datetime | {:null=>false} |
| created_at | html_repositories | datetime | {:null=>false} |
| created_at | major_systems | datetime | {:null=>false} |
| created_at | minor_systems | datetime | {:null=>false} |
| created_at | notification_logs | datetime | {:null=>false} |
| created_at | notifications | datetime | {:null=>false} |
| created_at | pointless_feedback_messages | datetime |  |
| created_at | preferred_geo_locations | datetime | {:null=>false} |
| created_at | providers | datetime | {:null=>false} |
| created_at | qm_assignments | datetime | {:null=>false} |
| created_at | question_modifiers | datetime | {:null=>false} |
| created_at | referral_appointments | datetime | {:null=>false} |
| created_at | referral_approvals | datetime | {:null=>false} |
| created_at | referral_documents | datetime | {:null=>false} |
| created_at | referral_notes | datetime | {:null=>false} |
| created_at | referrals | datetime | {:null=>false} |
| created_at | regional_offices | datetime | {:null=>false} |
| created_at | rejections | datetime | {:null=>false} |
| created_at | request_objects | datetime | {:null=>false} |
| created_at | rework_reason_free_texts | datetime | {:null=>false} |
| created_at | rework_reasons | datetime | {:null=>false} |
| created_at | service_periods | datetime | {:null=>false} |
| created_at | site_role_sets | datetime | {:null=>false} |
| created_at | sites | datetime | {:null=>false} |
| created_at | support_request_categories | datetime | {:null=>false} |
| created_at | support_request_organizations | datetime | {:null=>false} |
| created_at | support_requests | datetime | {:null=>false} |
| created_at | symp_diag_relations | datetime | {:null=>false} |
| created_at | symptoms | datetime | {:null=>false} |
| created_at | user_preferences | datetime | {:null=>false} |
| created_at | users | datetime |  |
| created_at | vbms_r_fact_groups | datetime | {:null=>false} |
| created_at | veterans | datetime | {:null=>false} |
| current_sign_in_at | users | datetime |  |
| current_sign_in_ip | users | inet |  |
| customer_email | support_requests | string | {:null=>false} |
| customer_organization | support_requests | string | {:null=>false} |
| customer_phone | support_requests | string | {:null=>false} |
| customer_site | support_requests | string | {:null=>false} |
| date_completed | alerts | datetime |  |
| date_of_birth | claims | date |  |
| dbq_information_id | boilerplate_messages_dbq_informations | integer | {:null=>false} |
| dbq_information_id | contentions_dbq_informations | integer | {:null=>false} |
| dbq_information_id | diagnoses_dbq_informations | integer | {:null=>false} |
| dbq_information_id | general_questions_dbq_informations | integer | {:null=>false} |
| dbq_information_id | symptoms_dbq_informations | integer | {:null=>false} |
| deleted_at | care_categories | datetime |  |
| deleted_at | clinics | datetime |  |
| deleted_at | consultation_orders | datetime |  |
| deleted_at | consultation_statuses | datetime |  |
| deleted_at | consultation_types | datetime |  |
| deleted_at | diagnosis_codes | datetime |  |
| deleted_at | medical_specialties | datetime |  |
| deleted_at | other_health_insurances | datetime |  |
| deleted_at | referral_document_types | datetime |  |
| deleted_at | referral_reasons | datetime |  |
| deleted_at | referral_types | datetime |  |
| deleted_at | sites | datetime |  |
| deleted_at | visns | datetime |  |
| dependent | evaluation_specs | string |  |
| description | alerts | text |  |
| description | contention_details | text |  |
| description | diagnosis_codes | string | {:null=>false} |
| description | pointless_feedback_messages | text |  |
| details | support_requests | string |  |
| diagnosis_id | diagnoses_dbq_informations | integer | {:null=>false} |
| diagnosis_id | dm_assignments | integer |  |
| diagnosis_id | symp_diag_relations | integer |  |
| diagnosis_info | vbms_r_fact_groups | text |  |
| diagnosis_modifier_id | diagnoses | integer |  |
| diagnosis_modifier_id | dm_assignments | integer |  |
| diagnosis_modifier_id | general_questions | integer |  |
| diagnosis_tag_name | vbms_r_fact_groups | string |  |
| doc | evaluations | json |  |
| document_title | vbms_r_fact_groups | string |  |
| edipi | claims | string |  |
| email | claims | string |  |
| email | users | string | {:default=>"", :null=>false} |
| email_address | exam_requesters | string |  |
| email_address | pointless_feedback_messages | string |  |
| encrypted_password | users | string | {:default=>"", :null=>false} |
| end_product_code | claims | string |  |
| entry_on_duty | service_periods | date |  |
| eras | service_periods | text |  |
| error_hash | exam_requests | text |  |
| evaluation_builder_title | evaluation_specs | string |  |
| evaluation_id | contentions_evaluations | integer |  |
| evaluation_id | evaluation_logs | integer |  |
| evaluation_id | examinations | integer |  |
| evaluation_id | examinations | reference |  |
| evaluation_spec_id | evaluations | integer |  |
| evaluation_template_id | major_systems | integer |  |
| event_id | clarification_details | string |  |
| event_id | contention_details | string |  |
| event_id | notification_logs | string |  |
| event_id | request_objects | string |  |
| evidence_comments | examination_review_questionnaires | boolean |  |
| evidence_comments_text | examination_review_questionnaires | text |  |
| exam_appointment_id | appointment_objects | string |  |
| exam_date | examinations | datetime |  |
| exam_date_time | examination_schedules | datetime |  |
| exam_id | examinations | integer |  |
| exam_related_contention_id | contention_objects | string |  |
| exam_related_contention_id | contentions | string |  |
| exam_request_data | claims | text |  |
| exam_request_id | contentions | integer |  |
| exam_request_id | exam_request_histories | integer |  |
| exam_request_id | examinations | integer |  |
| exam_request_state_id | exam_requests | integer |  |
| exam_request_status_id | exam_requests | integer |  |
| exam_requester_id | exam_requests | integer |  |
| exam_requester_id | exam_requests | reference |  |
| exam_response_fields | dm_assignments | string |  |
| exam_response_fields | qm_assignments | string |  |
| examfile | examinations | string |  |
| examfiles | examinations | string | {:default=>[], :array=>true} |
| examination_id | contentions_examinations | integer |  |
| examination_id | evaluations | integer |  |
| examination_id | examination_histories | integer |  |
| examination_id | examination_notes | integer |  |
| examination_id | examination_review_questionnaires | integer |  |
| examination_id | examination_schedules | integer |  |
| examination_id | evaluations | reference |  |
| examination_identifier | appointment_objects | string |  |
| examination_state_id | examinations | integer |  |
| examination_state_start_date | examinations | datetime |  |
| facility_id | providers | integer |  |
| facility_id | providers | reference |  |
| facility_name | claims | string |  |
| facility_number | claims | string |  |
| fact_block_tag_name | vbms_r_fact_groups | string |  |
| failed_at | delayed_jobs | datetime |  |
| failed_attempts | users | integer | {:default=>0} |
| file_number | claims | string |  |
| filterable_by_roles | referral_statuses | string |  |
| first_name | claims | string |  |
| first_name | exam_requesters | string |  |
| first_name | support_requests | string | {:null=>false} |
| first_name | users | string |  |
| first_name | veterans | string |  |
| format_type | diagnoses | integer | {:default=>0} |
| from_id | examination_notes | integer |  |
| gender | claims | string |  |
| general_question_id | general_questions_dbq_informations | integer | {:null=>false} |
| general_question_id | qm_assignments | integer |  |
| guid | evaluations | string |  |
| handler | delayed_jobs | text | {:null=>false} |
| history | contentions | text |  |
| html | html_repositories | text |  |
| html | question_modifiers | text |  |
| identifier | contentions | string |  |
| identifier | dbq_informations | string |  |
| identifier | exam_requests | string |  |
| identifier | examinations | string |  |
| insufficient | contentions | boolean | {:default=>false} |
| integration_control_number | claims | string |  |
| interview | examinations | text |  |
| is_contention_cancelled | contentions | boolean |  |
| is_under_review | users | boolean | {:default=>true} |
| issue_description | support_requests | string | {:null=>false} |
| label | claims | string |  |
| label | diagnoses | string |  |
| label | diagnosis_modifiers | string |  |
| label | dm_assignments | string |  |
| label | evaluation_templates | string |  |
| label | general_questions | string |  |
| label | major_systems | string |  |
| label | minor_systems | string |  |
| label | qm_assignments | string |  |
| label | question_modifiers | string |  |
| label | symptoms | string |  |
| last_error | delayed_jobs | text |  |
| last_name | claims | string |  |
| last_name | exam_requesters | string |  |
| last_name | support_requests | string | {:null=>false} |
| last_name | users | string |  |
| last_name | veterans | string |  |
| last_sign_in_at | users | datetime |  |
| last_sign_in_ip | users | inet |  |
| list_values | diagnosis_modifiers | string | {:default=>[], :array=>true} |
| list_values | question_modifiers | string | {:default=>[], :array=>true} |
| locked_at | delayed_jobs | datetime |  |
| locked_at | users | datetime |  |
| locked_by | delayed_jobs | string |  |
| long_name | support_request_organizations | string | {:null=>false} |
| mailing_address | regional_offices | text |  |
| major_system_id | minor_systems | integer |  |
| medical_specialty_id | medical_specialties_providers | integer |  |
| message | evaluation_logs | text |  |
| message | notification_logs | text |  |
| middle_name | claims | string |  |
| middle_name | veterans | string |  |
| minor_system_id | diagnoses | integer |  |
| minor_system_id | general_questions | integer |  |
| minor_system_id | symptoms | integer |  |
| mod_type | diagnosis_modifiers | string |  |
| mod_type | question_modifiers | string |  |
| name | boilerplate_messages | string |  |
| name | clarification_types | string |  |
| name | clinics | string |  |
| name | contention_details | string |  |
| name | contentions | text |  |
| name | diagnoses | string |  |
| name | diagnosis_modifiers | string |  |
| name | dm_assignments | string |  |
| name | evaluation_templates | string |  |
| name | exam_request_states | string |  |
| name | examination_states | string |  |
| name | facilities | string |  |
| name | general_questions | string |  |
| name | html_repositories | string |  |
| name | major_systems | string |  |
| name | minor_systems | string |  |
| name | pointless_feedback_messages | string |  |
| name | providers | string | {:null=>false} |
| name | qm_assignments | string |  |
| name | question_modifiers | string |  |
| name | referral_statuses | string |  |
| name | sites | string |  |
| name | support_request_categories | string | {:null=>false} |
| name | symptoms | string |  |
| name | vbms_r_fact_groups | string |  |
| name | visns | string |  |
| namespace | vbms_r_fact_groups | string |  |
| negative_show | dm_assignments | boolean | {:default=>false, :null=>false} |
| negative_show | qm_assignments | boolean | {:default=>false, :null=>false} |
| no_diagnosis | contentions | boolean |  |
| no_records_were_reviewed | examination_review_questionnaires | boolean |  |
| non_vha | site_role_sets | boolean | {:default=>false, :null=>false} |
| not_requested | examination_review_questionnaires | boolean |  |
| note | examination_notes | text |  |
| notes | exam_request_histories | string |  |
| notes | examination_histories | string |  |
| notification_type | alerts | string |  |
| notification_type | notification_logs | string |  |
| npi | providers | string | {:null=>false} |
| ordering_provider_id | consultations | integer |  |
| organization | exam_requesters | string |  |
| other | examination_review_questionnaires | boolean |  |
| other_health_insurance_id | veterans | integer |  |
| other_health_insurance_id | veterans | reference |  |
| other_health_insurance_name | veterans | string |  |
| other_text | examination_review_questionnaires | text |  |
| participant_id | claims | string |  |
| participating_system_name | exam_requests | string |  |
| patient_ssn | claims | string |  |
| phone_number | claims | string |  |
| physical_address | regional_offices | text |  |
| physician_name | providers | string | {:null=>false} |
| plan | examinations | text |  |
| poa_vso_name | claims | string |  |
| poa_vso_number | claims | string |  |
| position | boilerplate_messages_dbq_informations | integer |  |
| position | contentions_dbq_informations | integer |  |
| position | diagnoses | integer |  |
| position | diagnoses_dbq_informations | integer |  |
| position | dm_assignments | integer |  |
| position | general_questions | integer |  |
| position | general_questions_dbq_informations | integer |  |
| position | major_systems | integer |  |
| position | minor_systems | integer |  |
| position | qm_assignments | integer |  |
| position | symptoms | integer |  |
| position | symptoms_dbq_informations | integer |  |
| previously_worked_contention_id | contentions | string |  |
| primary_evaluation_id | evaluations | integer |  |
| primary_phone | exam_requesters | integer |  |
| priority | delayed_jobs | integer | {:default=>0, :null=>false} |
| provider | users | string |  |
| provider_id | medical_specialties_providers | integer |  |
| provider_id | providers_users | integer |  |
| provider_id | referrals | integer |  |
| provider_id | providers_users | reference |  |
| provider_id | referrals | reference |  |
| purpose | examinations | string |  |
| qa | site_role_sets | boolean | {:default=>false, :null=>false} |
| question_modifier_id | qm_assignments | integer |  |
| question_type | general_questions | integer | {:default=>0} |
| queue | delayed_jobs | string |  |
| reason | rejections | string |  |
| reason | rework_reason_free_texts | text |  |
| reason | rework_reasons | text |  |
| reason_for_cancellation | contentions | text |  |
| referral_document_type_id | referral_documents | integer |  |
| referral_filter | user_preferences | json | {:default=>{}} |
| referral_id | referral_appointments | integer |  |
| referral_id | referral_approvals | integer |  |
| referral_id | referral_documents | integer |  |
| referral_id | referral_notes | integer |  |
| referral_id | referral_appointments | reference |  |
| referral_id | referral_approvals | reference |  |
| referral_id | referral_documents | reference |  |
| referral_id | referral_notes | reference |  |
| referral_number | referrals | string | {:null=>false} |
| referral_queue | referral_statuses | string |  |
| referral_reason_id | referrals | integer |  |
| referral_reason_id | referrals | reference |  |
| referral_status_id | referrals | integer |  |
| referral_status_id | referrals | reference |  |
| referral_type_id | referrals | integer |  |
| referral_type_id | referrals | reference |  |
| region | visns | integer |  |
| regional_office_id | claims | integer |  |
| remember_created_at | users | datetime |  |
| request_date | exam_requests | datetime |  |
| request_id | exam_requests | string |  |
| request_type | request_objects | string |  |
| requested_by | alerts | integer | {:null=>false} |
| reschedule_reason | examination_schedules | text |  |
| reset_password_sent_at | users | datetime |  |
| reset_password_token | users | string |  |
| resolved_at | contentions | datetime |  |
| response_body | evaluation_logs | text |  |
| response_body | notification_logs | text |  |
| reviewed_at | contentions | datetime |  |
| reviewed_at | evaluations | datetime |  |
| reviewed_at | examinations | datetime |  |
| reviewed_by | contentions | integer |  |
| reviewed_by | examinations | integer |  |
| reviewed_civilian_medical_records | contentions | boolean |  |
| reviewed_civilian_medical_records | examination_review_questionnaires | boolean |  |
| reviewed_dod_form_214_separation_documents | contentions | boolean |  |
| reviewed_dod_form_214_separation_documents | examination_review_questionnaires | boolean |  |
| reviewed_interviews_with_collateral_witnesses | contentions | boolean |  |
| reviewed_interviews_with_collateral_witnesses | examination_review_questionnaires | boolean |  |
| reviewed_military_enlistment_examination | contentions | boolean |  |
| reviewed_military_enlistment_examination | examination_review_questionnaires | boolean |  |
| reviewed_military_post_deployment_questionnaire | contentions | boolean |  |
| reviewed_military_post_deployment_questionnaire | examination_review_questionnaires | boolean |  |
| reviewed_military_separation_examination | contentions | boolean |  |
| reviewed_military_separation_examination | examination_review_questionnaires | boolean |  |
| reviewed_military_service_personnel_records | contentions | boolean |  |
| reviewed_military_service_personnel_records | examination_review_questionnaires | boolean |  |
| reviewed_military_service_treatment_records | contentions | boolean |  |
| reviewed_military_service_treatment_records | examination_review_questionnaires | boolean |  |
| reviewed_not_indicated | contentions | boolean |  |
| reviewed_not_indicated | examination_review_questionnaires | boolean |  |
| reviewed_vha_treatment_records | contentions | boolean |  |
| reviewed_vha_treatment_records | examination_review_questionnaires | boolean |  |
| role_requests | sites | string | {:default=>[], :array=>true} |
| roles | users | text |  |
| run_at | delayed_jobs | datetime |  |
| scheduling | site_role_sets | boolean | {:default=>false, :null=>false} |
| sequence | care_categories | string | {:null=>false} |
| sequence | consultation_orders | string | {:null=>false} |
| sequence | consultation_statuses | string | {:null=>false} |
| sequence | consultation_types | string | {:null=>false} |
| sequence | medical_specialties | string | {:null=>false} |
| sequence | other_health_insurances | string | {:null=>false} |
| sequence | referral_document_types | string | {:null=>false} |
| sequence | referral_reasons | string | {:null=>false} |
| sequence | referral_types | string | {:null=>false} |
| sequence | visns | string |  |
| service_end_date | service_periods | date |  |
| severity | support_requests | integer |  |
| short_name | support_request_organizations | string | {:null=>false} |
| sign_in_count | users | integer | {:default=>0, :null=>false} |
| site | alerts | integer |  |
| site_id | clinics | integer |  |
| site_id | exam_requests | integer |  |
| site_id | examinations | integer |  |
| site_id | site_role_sets | integer |  |
| site_station_number | sites | string |  |
| spec | evaluation_specs | text |  |
| spec_id | evaluation_specs | string |  |
| special_issue | exam_prioritization_special_issues | text |  |
| special_issues | exam_requests | string |  |
| ssn | veterans | string | {:limit=>10, :null=>false} |
| state | examinations | integer |  |
| state | preferred_geo_locations | string |  |
| state | sites | string |  |
| station_number | regional_offices | string |  |
| submitted_data | evaluation_logs | text |  |
| submitted_xml_data | notification_logs | text |  |
| super_clinician | site_role_sets | boolean | {:default=>false, :null=>false} |
| supervised_id | supervised_clinicians | integer |  |
| supervisor_id | supervising_clinicians | integer |  |
| symptom_id | symp_diag_relations | integer |  |
| symptom_id | symptoms_dbq_informations | integer | {:null=>false} |
| symptom_info | vbms_r_fact_groups | text |  |
| symptom_tag_name | vbms_r_fact_groups | string |  |
| text | clarification_details | text |  |
| text | vbms_r_fact_groups | string |  |
| ticket_number | support_requests | string | {:null=>false} |
| time_zone | user_preferences | string |  |
| title | care_categories | string | {:null=>false} |
| title | consultation_orders | string | {:null=>false} |
| title | consultation_statuses | string | {:null=>false} |
| title | consultation_types | string | {:null=>false} |
| title | dbq_informations | string |  |
| title | evaluation_specs | text |  |
| title | examinations | string |  |
| title | medical_specialties | string | {:null=>false} |
| title | other_health_insurances | string | {:null=>false} |
| title | referral_document_types | string | {:null=>false} |
| title | referral_reasons | string | {:null=>false} |
| title | referral_types | string | {:null=>false} |
| to_id | examination_notes | integer |  |
| topic | pointless_feedback_messages | string |  |
| triage | site_role_sets | boolean | {:default=>false, :null=>false} |
| type | examination_notes | string |  |
| uid | users | string |  |
| unlock_token | users | string |  |
| update_description | referral_statuses | string |  |
| updated_at | alerts | datetime | {:null=>false} |
| updated_at | appointment_objects | datetime | {:null=>false} |
| updated_at | boilerplate_messages | datetime | {:null=>false} |
| updated_at | claims | datetime |  |
| updated_at | clarification_details | datetime | {:null=>false} |
| updated_at | clarification_types | datetime | {:null=>false} |
| updated_at | consultations | datetime | {:null=>false} |
| updated_at | contention_details | datetime | {:null=>false} |
| updated_at | contention_objects | datetime | {:null=>false} |
| updated_at | contentions | datetime |  |
| updated_at | dashboards | datetime | {:null=>false} |
| updated_at | dbq_informations | datetime | {:null=>false} |
| updated_at | delayed_jobs | datetime |  |
| updated_at | diagnoses | datetime | {:null=>false} |
| updated_at | diagnosis_modifiers | datetime | {:null=>false} |
| updated_at | dm_assignments | datetime | {:null=>false} |
| updated_at | evaluation_logs | datetime |  |
| updated_at | evaluation_specs | datetime |  |
| updated_at | evaluation_templates | datetime | {:null=>false} |
| updated_at | evaluations | datetime |  |
| updated_at | exam_management_notifications | datetime | {:null=>false} |
| updated_at | exam_request_histories | datetime | {:null=>false} |
| updated_at | exam_request_processors | datetime | {:null=>false} |
| updated_at | exam_request_states | datetime | {:null=>false} |
| updated_at | exam_requests | datetime |  |
| updated_at | examination_histories | datetime | {:null=>false} |
| updated_at | examination_notes | datetime | {:null=>false} |
| updated_at | examination_review_questionnaires | datetime | {:null=>false} |
| updated_at | examination_schedules | datetime | {:null=>false} |
| updated_at | examinations | datetime | {:null=>false} |
| updated_at | general_questions | datetime | {:null=>false} |
| updated_at | html_repositories | datetime | {:null=>false} |
| updated_at | major_systems | datetime | {:null=>false} |
| updated_at | minor_systems | datetime | {:null=>false} |
| updated_at | notification_logs | datetime | {:null=>false} |
| updated_at | notifications | datetime | {:null=>false} |
| updated_at | pointless_feedback_messages | datetime |  |
| updated_at | preferred_geo_locations | datetime | {:null=>false} |
| updated_at | providers | datetime | {:null=>false} |
| updated_at | qm_assignments | datetime | {:null=>false} |
| updated_at | question_modifiers | datetime | {:null=>false} |
| updated_at | referral_appointments | datetime | {:null=>false} |
| updated_at | referral_approvals | datetime | {:null=>false} |
| updated_at | referral_documents | datetime | {:null=>false} |
| updated_at | referral_notes | datetime | {:null=>false} |
| updated_at | referrals | datetime | {:null=>false} |
| updated_at | regional_offices | datetime | {:null=>false} |
| updated_at | rejections | datetime | {:null=>false} |
| updated_at | request_objects | datetime | {:null=>false} |
| updated_at | rework_reason_free_texts | datetime | {:null=>false} |
| updated_at | rework_reasons | datetime | {:null=>false} |
| updated_at | service_periods | datetime | {:null=>false} |
| updated_at | site_role_sets | datetime | {:null=>false} |
| updated_at | sites | datetime | {:null=>false} |
| updated_at | support_request_categories | datetime | {:null=>false} |
| updated_at | support_request_organizations | datetime | {:null=>false} |
| updated_at | support_requests | datetime | {:null=>false} |
| updated_at | symp_diag_relations | datetime | {:null=>false} |
| updated_at | symptoms | datetime | {:null=>false} |
| updated_at | user_preferences | datetime | {:null=>false} |
| updated_at | users | datetime |  |
| updated_at | vbms_r_fact_groups | datetime | {:null=>false} |
| updated_at | veterans | datetime | {:null=>false} |
| uploader_id | referral_documents | integer |  |
| user_id | evaluations | integer |  |
| user_id | providers_users | integer |  |
| user_id | site_role_sets | integer |  |
| user_id | supervised_clinicians | integer |  |
| user_id | supervising_clinicians | integer |  |
| user_id | user_preferences | integer |  |
| user_id | providers_users | reference |  |
| user_id | referral_appointments | reference |  |
| user_id | user_preferences | reference |  |
| va_claims_file | examination_review_questionnaires | boolean |  |
| va_e_folder | examination_review_questionnaires | boolean |  |
| valid_from | consultations | datetime |  |
| valid_to | consultations | datetime |  |
| vba_diagnostic_code | contentions | string |  |
| vbms_claim_id | claims | string |  |
| version | evaluation_specs | text |  |
| version_code | diagnosis_codes | string | {:null=>false} |
| veteran_dob | consultations | string |  |
| veteran_first_name | consultations | string |  |
| veteran_last_name | consultations | string |  |
| veteran_local_pid | consultations | string |  |
| veteran_middle_name | consultations | string |  |
| veteran_mpi_pid | consultations | string |  |
| veteran_other_health_insurance_name | consultations | string |  |
| veteran_ssn | consultations | string |  |
| vha_cc | site_role_sets | boolean | {:default=>false, :null=>false} |
| vha_user_electronic_signature | evaluations | string |  |
| vha_user_vista_access_code | evaluations | string |  |
| vha_user_vista_verify_code | evaluations | string |  |
| via_created_date | consultations | string |  |
| visn_id | facilities | integer |  |
| visn_id | facilities | reference |  |
| vista_duz | user_preferences | string |  |
| vista_ien | claims | string |  |
| vista_site_id | user_preferences | string |  |
| vista_user_name | user_preferences | string |  |
| xml | appointment_objects | text |  |
| xml | contention_objects | text |  |
| xml | exam_management_notifications | text |  |
| xml | exam_requests | text |  |
| xml | request_objects | text |  |
| zip | preferred_geo_locations | string |  |
| zip_code | sites | string |  |
