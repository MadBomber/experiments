class FixMigrationQualityIssues < ActiveRecord::Migration[8.1]
  def change
    # Fix: character FK on transcript_lines should nullify on delete
    # (character_id is nullable; deleting a character should null out the references)
    remove_foreign_key :transcript_lines, :characters
    add_foreign_key    :transcript_lines, :characters, on_delete: :nullify

    # Fix: missing indexes on soft-reference integer columns
    add_index :scenes,              :released_by
    add_index :scene_runs,          :started_by
    add_index :research_materials,  :character_id
    add_index :research_materials,  :scene_id
    add_index :scene_comments,      :resolved_by_id
  end
end
