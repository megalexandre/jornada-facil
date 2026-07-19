# frozen_string_literal: true

class SimplifyRbacCatalog < ActiveRecord::Migration[8.1]
  def up
    # Soft-deleted rows would silently come back to life once deleted_at is
    # gone, so purge them first (role_permissions/user_roles cascade via FK).
    execute "DELETE FROM permissions WHERE deleted_at IS NOT NULL"
    execute "DELETE FROM roles WHERE deleted_at IS NOT NULL"

    remove_column :permissions, :name
    remove_column :permissions, :deleted_at
    remove_column :roles, :deleted_at
  end

  def down
    add_column :permissions, :name, :string
    execute "UPDATE permissions SET name = resource || ':' || action"
    change_column_null :permissions, :name, false
    add_index :permissions, :name, unique: true

    add_column :permissions, :deleted_at, :datetime
    add_index :permissions, :deleted_at
    add_column :roles, :deleted_at, :datetime
    add_index :roles, :deleted_at
  end
end
