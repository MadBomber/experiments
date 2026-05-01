class MakeTranscriptLineCharacterNullable < ActiveRecord::Migration[8.1]
  def change
    change_column_null :transcript_lines, :character_id, true
  end
end
