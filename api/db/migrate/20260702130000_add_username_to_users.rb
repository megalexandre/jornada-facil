# frozen_string_literal: true

class AddUsernameToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :username, :string

    User.reset_column_information
    User.unscoped.find_each do |user|
      base = user.email.to_s.split("@").first.presence&.parameterize(separator: "_") || "user"
      candidate = base
      counter = 1
      while User.unscoped.where(username: candidate).where.not(id: user.id).exists?
        counter += 1
        candidate = "#{base}#{counter}"
      end
      user.update_column(:username, candidate)
    end

    change_column_null :users, :username, false
    add_index :users, :username, unique: true
  end
end
