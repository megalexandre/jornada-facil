# frozen_string_literal: true

class AddResourceAndActionToPermissions < ActiveRecord::Migration[8.1]
  def change
    add_column :permissions, :resource, :string
    add_column :permissions, :action, :string

    Permission.reset_column_information
    Permission.find_each do |permission|
      parts = permission.name.split(':')
      permission.update(
        resource: parts[0] || permission.name,
        action: parts[1] || 'read'
      )
    end

    change_column_null :permissions, :resource, false
    change_column_null :permissions, :action, false
    add_index :permissions, [ :resource, :action ], unique: true
  end
end
