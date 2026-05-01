class AddActorIdIndexToUsers < ActiveRecord::Migration[8.1]
  def change
    add_index :users, :actor_id
  end
end
