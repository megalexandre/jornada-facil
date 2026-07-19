# frozen_string_literal: true

ACTION_LABELS = {
  "view" => "Visualizar",
  "create" => "Criar",
  "update" => "Atualizar",
  "delete" => "Remover"
}.freeze

(Rbac::ADMIN_RESOURCES + Rbac::DOMAIN_RESOURCES).each do |resource|
  Rbac::ACTIONS.each do |action|
    Permission.find_or_create_by!(resource: resource, action: action) do |p|
      p.description = "#{ACTION_LABELS[action]} #{resource}"
    end
  end
end

admin_role = Role.find_or_create_by!(name: "admin") { |r| r.description = "Acesso total ao sistema" }
Permission.all.each { |permission| RolePermission.find_or_create_by!(role: admin_role, permission: permission) }

user_role = Role.find_or_create_by!(name: "user") { |r| r.description = "Usuário autenticado padrão" }
# Usuário padrão enxerga o domínio e opera a própria jornada (abrir/fechar).
user_grants = Permission.where(resource: Rbac::DOMAIN_RESOURCES, action: "view")
  .or(Permission.where(resource: "journey", action: %w[create update]))
user_grants.each do |permission|
  RolePermission.find_or_create_by!(role: user_role, permission: permission)
end

if Rails.env.development?
  admin_user = User.find_or_create_by!(username: "admin") do |u|
    u.name = "Admin"
    u.email = "admin@example.com"
    u.password = u.password_confirmation = "Password123!"
    u.tracks_journey = false # admin não bate ponto
  end
  UserRole.find_or_create_by!(user: admin_user, role: admin_role)
end
