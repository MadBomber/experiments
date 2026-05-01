class AddNameIndexesToActorsAndCharacters < ActiveRecord::Migration[8.1]
  def change
    add_index :actors,     :name
    add_index :characters, :name
  end
end
