class CreateBeats < ActiveRecord::Migration[8.1]
  def change
    create_table :beats do |t|
      t.references :project,   null: false, foreign_key: true
      t.string     :title,     null: false
      t.text       :description
      t.integer    :act                                      # 1, 2, 3 etc.
      t.integer    :position,  null: false, default: 0      # drag-reorder order
      t.string     :beat_type, null: false, default: "general"
        # enum values: inciting_incident / plot_point_1 / midpoint /
        #              plot_point_2 / climax / resolution / general
      t.integer    :scene_id                                 # nullable FK — links beat to scene once written

      t.timestamps
    end

    add_index :beats, [:project_id, :position]
    add_index :beats, :beat_type
    add_index :beats, :scene_id
  end
end
