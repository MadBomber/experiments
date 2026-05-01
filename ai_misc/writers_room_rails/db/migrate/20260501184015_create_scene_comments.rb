class CreateSceneComments < ActiveRecord::Migration[8.1]
  def change
    create_table :scene_comments do |t|
      t.references :scene,              null: false, foreign_key: true
      t.references :user,               null: false, foreign_key: true
      t.integer    :transcript_line_id                       # optional — line-anchored or free-floating
      t.text       :body,               null: false
      t.boolean    :resolved,           null: false, default: false
      t.integer    :resolved_by_id

      t.timestamps
    end

    add_index :scene_comments, [:scene_id, :resolved]
    add_index :scene_comments, :transcript_line_id
  end
end
