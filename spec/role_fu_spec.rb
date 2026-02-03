# frozen_string_literal: true

RSpec.describe RoleFu do
  let(:user) { User.create(name: "Test User") }
  let(:organization) { Organization.create(name: "Test Org") }

  it "has a version number" do
    expect(RoleFu::VERSION).not_to be nil
  end

  describe "Global Roles" do
    it "adds a global role" do
      user.add_role(:admin)
      expect(user.has_role?(:admin)).to be true
      expect(user.roles.count).to eq(1)
      expect(user.roles.first.name).to eq("admin")
      expect(user.roles.first.resource).to be_nil
    end

    it "removes a global role" do
      user.add_role(:admin)
      user.remove_role(:admin)
      expect(user.has_role?(:admin)).to be false
      expect(user.roles.count).to eq(0)
    end
  end

  describe "Resource Roles" do
    it "adds a resource role" do
      user.add_role(:member, organization)
      expect(user.has_role?(:member, organization)).to be true
      expect(user.has_role?(:member)).to be false # strict check
      expect(user.has_role?(:member, :any)).to be true
    end

    it "removes a resource role" do
      user.add_role(:member, organization)
      user.remove_role(:member, organization)
      expect(user.has_role?(:member, organization)).to be false
    end
  end

  describe "Cached Roles (N+1 prevention)" do
    it "uses cached roles when preloaded" do
      user.add_role(:admin)
      user.add_role(:member, organization)
      
      # Simulate preloading
      preloaded_user = User.includes(:roles).find(user.id)
      
      expect(preloaded_user.has_cached_role?(:admin)).to be true
      expect(preloaded_user.has_cached_role?(:member, organization)).to be true
      expect(preloaded_user.has_cached_role?(:non_existent)).to be false
    end
  end

  describe "Callbacks" do
    it "runs callbacks when adding a role" do
      user.add_role(:manager)
      expect(user.callback_log).to include("before_add_manager")
      expect(user.callback_log).to include("after_add_manager")
    end
  end

  describe "Resourceable" do
    before do
      user.add_role(:admin, organization)
    end

    it "finds users with role" do
      users = organization.users_with_role(:admin)
      expect(users).to include(user)
    end

    it "counts users with role" do
      expect(organization.count_users_with_role(:admin)).to eq(1)
    end

    it "checks if resource has role" do
      expect(organization.has_role?(:admin)).to be true
    end
  end

  describe "Cleanup" do
    it "deletes role when last user is removed" do
      user.add_role(:unique_role)
      role = Role.find_by(name: "unique_role")
      expect(role).to be_present

      user.remove_role(:unique_role)
      expect(Role.find_by(name: "unique_role")).to be_nil
    end

    it "does not delete role if other users have it" do
      user2 = User.create(name: "User 2")
      user.add_role(:shared_role)
      user2.add_role(:shared_role)

      user.remove_role(:shared_role)
      expect(Role.find_by(name: "shared_role")).to be_present
    end
  end
end