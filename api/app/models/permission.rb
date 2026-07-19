# frozen_string_literal: true

class Permission < ApplicationRecord
  has_many :role_permissions, dependent: :destroy
  has_many :roles, through: :role_permissions

  validates :resource, :action, presence: true
  validates :resource, uniqueness: { scope: :action }

  def to_rbac
    "#{resource}:#{action}"
  end
end
