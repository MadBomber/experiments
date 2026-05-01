# frozen_string_literal: true

class CreateTranscriptLines < ActiveRecord::Migration[8.1]
  def change
    create_table :transcript_lines do |t|
      t.references :scene_run,    null: false, foreign_key: true
      t.references :character,    null: false, foreign_key: true
      t.text       :content,      null: false
      t.string     :emotion
      t.string     :addressing
      t.integer    :position,     null: false
      # Screenplay format fields (from Final Draft research)
      t.string     :element_type,    default: "dialogue"   # action/character/parenthetical/dialogue/transition/scene_heading
      t.string     :parenthetical                          # delivery instruction e.g. "(softly)"
      t.string     :voice_qualifier, default: "none"       # none/os/vo/cont

      t.timestamps
    end

    add_index :transcript_lines, [:scene_run_id, :position]
  end
end
