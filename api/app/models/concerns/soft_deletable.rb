# frozen_string_literal: true

module SoftDeletable
  extend ActiveSupport::Concern

  included do
    default_scope { where(deleted_at: nil) }
  end

  def soft_delete(deleted_by = nil)
    update(deleted_at: Time.current, updated_by: deleted_by)
  end

  def deleted?
    deleted_at.present?
  end
end
