class CreateResearchMaterials < ActiveRecord::Migration[8.1]
  def change
    create_table :research_materials do |t|
      t.string     :subject,    null: false
      t.string     :category,   null: false, default: "other"
      t.references :project,    null: false, foreign_key: true
      t.integer    :character_id
      t.integer    :scene_id
      t.text       :summary
      t.text       :key_facts
      t.text       :world_building_notes
      t.text       :accuracy_requirements
      t.text       :sources

      t.timestamps
    end

    add_index :research_materials, :category
  end
end
