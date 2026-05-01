class RemoveRedundantUserIdIndexFromUserRoles < ActiveRecord::Migration[8.1]
  def change
    remove_index :user_roles, :user_id
  end
end
