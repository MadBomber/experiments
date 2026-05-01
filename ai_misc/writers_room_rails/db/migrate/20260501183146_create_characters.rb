class CreateCharacters < ActiveRecord::Migration[8.1]
  def change
    create_table :characters do |t|
      t.string  :name,                null: false
      t.string  :archetype
      t.text    :personality
      t.text    :voice_pattern
      t.text    :character_arc
      t.text    :motivation
      t.text    :internal_conflict
      t.text    :physical_description
      t.text    :mannerisms
      # robot_lab agent state
      t.string  :model
      t.string  :provider
      t.text    :data
      t.integer :input_tokens,  default: 0, null: false
      t.integer :output_tokens, default: 0, null: false
      t.integer :total_tokens,  default: 0, null: false

      t.timestamps
    end
  end
end
