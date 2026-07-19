# frozen_string_literal: true

require "rails_helper"

RSpec.describe Rbac::GetPermissionsService do
  let(:user) { create(:user) }
  let(:role) { create(:role) }

  before { user.roles << role }

  def grant(resource, *actions)
    actions.each { |action| role.permissions << create(:permission, resource: resource, action: action) }
  end

  it "returns explicit sorted tokens for partial coverage of a resource" do
    grant("journey", "view", "update")
    grant("history", "view")

    expect(described_class.call(user: user)).to eq([ "history:view", "journey:update", "journey:view" ])
  end

  it "folds a fully covered resource into resource:*" do
    grant("journey", *Rbac::ACTIONS)
    grant("history", "view")

    expect(described_class.call(user: user)).to eq([ "history:view", "journey:*" ])
  end

  it "keeps explicit resource:* tokens for full domain coverage only" do
    Rbac::DOMAIN_RESOURCES.each { |resource| grant(resource, *Rbac::ACTIONS) }

    expect(described_class.call(user: user)).to eq([ "history:*", "journey:*", "profile:*" ])
  end

  it "folds full catalog coverage into a single *" do
    Rbac::ALL_RESOURCES.each { |resource| grant(resource, *Rbac::ACTIONS) }

    expect(described_class.call(user: user)).to eq([ "*" ])
  end

  it "serializes admin resources alongside domain resources" do
    grant("users", *Rbac::ACTIONS)
    grant("journey", "view")

    expect(described_class.call(user: user)).to eq([ "journey:view", "users:*" ])
  end

  it "deduplicates permissions granted through multiple roles" do
    other_role = create(:role)
    user.roles << other_role
    permission = create(:permission, resource: "journey", action: "view")
    role.permissions << permission
    other_role.permissions << permission

    expect(described_class.call(user: user)).to eq([ "journey:view" ])
  end

  it "returns an empty array for a user without permissions" do
    expect(described_class.call(user: user)).to eq([])
  end
end
