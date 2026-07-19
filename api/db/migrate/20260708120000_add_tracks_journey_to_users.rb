# frozen_string_literal: true

class AddTracksJourneyToUsers < ActiveRecord::Migration[8.1]
  def up
    add_column :users, :tracks_journey, :boolean, null: false, default: true

    # Admins não batem ponto: desliga o bit para quem já tem o papel "admin"
    # (cobre o admin de produção já provisionado).
    User.reset_column_information
    admin_ids = UserRole.joins(:role).where(roles: { name: "admin" }).select(:user_id)
    User.unscoped.where(id: admin_ids).update_all(tracks_journey: false)
  end

  def down
    remove_column :users, :tracks_journey
  end
end
