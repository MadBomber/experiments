class CreateActors < ActiveRecord::Migration[8.1]
  def change
    create_table :actors do |t|
      t.string :name, null: false
      t.text   :description
      t.text   :style_notes
      t.string :preferred_model
      t.string :preferred_provider

      t.timestamps
    end
  end
end
