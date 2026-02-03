# frozen_string_literal: true

RSpec.describe RoleFu do
  let(:user) { User.create(name: "Test User") }
  let(:organization) { Organization.create(name: "Test Org") }

  it "has a version number" do
    expect(RoleFu::VERSION).not_to be_nil
  end

  it "allows configuration" do
    described_class.configure do |config|
      config.user_class_name = "User"
    end
    expect(described_class.configuration.user_class_name).to eq("User")
  end

  describe "Global Roles" do
    it "adds a global role" do
      user.grant(:admin)
      expect(user.has_role?(:admin)).to be true
      expect(user.roles.count).to eq(1)
      expect(user.roles.first.name).to eq("admin")
      expect(user.roles.first.resource).to be_nil
    end

    it "removes a global role" do
      user.grant(:admin)
      user.revoke(:admin)
      expect(user.has_role?(:admin)).to be false
      expect(user.roles.count).to eq(0)
    end

    it "checks strict roles" do
      user.grant(:admin)
      expect(user.has_strict_role?(:admin)).to be true
      expect(user.has_strict_role?(:admin, organization)).to be false
    end

    it "checks only_has_role?" do
      user.grant(:admin)
      expect(user.only_has_role?(:admin)).to be true

      user.grant(:manager)
      expect(user.only_has_role?(:admin)).to be false
    end

    it "checks has_only_global_roles?" do
      user.add_role(:admin)
      expect(user.has_only_global_roles?).to be true
      user.add_role(:member, organization)
      expect(user.has_only_global_roles?).to be false
    end
  end

  describe "Scopes" do
    let!(:user2) { User.create(name: "User 2") }

    before do
      user.add_role(:admin)
      user.add_role(:manager, organization)
      user2.add_role(:editor)
    end

    describe "User scopes" do
      it "finds users with global role" do
        users = User.with_role(:admin)
        expect(users).to include(user)
        expect(users).not_to include(user2)
      end

      it "finds users with resource role" do
        users = User.with_role(:manager, organization)
        expect(users).to include(user)
        expect(users).not_to include(user2)
      end

      it "finds users with any role" do
        users = User.with_any_role(:admin, :editor)
        expect(users).to include(user, user2)
      end

      it "finds users with any resource role" do
        users = User.with_role(:manager, :any)
        expect(users).to include(user)
      end

      it "finds users with class-level resource role" do
        user.add_role(:manager, Organization)
        users = User.with_role(:manager, Organization)
        expect(users).to include(user)
      end

      it "finds users without role" do
        users = User.without_role(:admin)
        expect(users).to include(user2)
        expect(users).not_to include(user)
      end

      it "finds users with all roles" do
        user.add_role(:editor)
        users = User.with_all_roles(:admin, :editor)
        expect(users).to include(user)
        expect(users).not_to include(user2)
      end

      it "returns none if with_all_roles finds nothing" do
        users = User.with_all_roles(:admin, :non_existent)
        expect(users).to be_empty
      end
    end

    describe "Resource scopes" do
      it "finds resources with role applied to user" do
        orgs = Organization.with_role(:manager, user)
        expect(orgs).to include(organization)
      end

      it "finds resources without role applied to user" do
        org2 = Organization.create(name: "Other Org")
        orgs = Organization.without_role(:manager, user)
        expect(orgs).to include(org2)
        expect(orgs).not_to include(organization)
      end

      it "finds roles for a resource class" do
        roles = Organization.find_roles(:manager, user)
        expect(roles.count).to eq(1)
        expect(roles.first.name).to eq("manager")
      end
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

    it "checks has_any_role?" do
      expect(user.has_any_role?).to be false
      user.add_role(:admin)
      expect(user.has_any_role?).to be true
      expect(user.has_any_role?(organization)).to be false
      user.add_role(:member, organization)
      expect(user.has_any_role?(organization)).to be true
    end

    it "checks has_all_roles?" do
      user.add_role(:admin)
      expect(user.has_all_roles?(:admin)).to be true
      expect(user.has_all_roles?(:admin, :manager)).to be false
    end

    it "checks has_any_role_of?" do
      user.add_role(:admin)
      expect(user.has_any_role_of?(:admin, :manager)).to be true
      expect(user.has_any_role_of?(:manager, :editor)).to be false
    end

    it "gets resources for a class" do
      user.add_role(:manager, organization)
      expect(user.resources(Organization)).to include(organization)
    end

    it "returns roles names" do
      user.add_role(:admin)
      user.add_role(:member, organization)
      expect(user.roles_name).to include("admin", "member")
      expect(user.roles_name(organization)).to include("member")
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
      expect(preloaded_user.has_cached_role?(:member, :any)).to be true

      # Class check
      expect(preloaded_user.has_cached_role?(:member, Organization)).to be false
      user.add_role(:manager, Organization)
      preloaded_user = User.includes(:roles).find(user.id)
      expect(preloaded_user.has_cached_role?(:manager, Organization)).to be true
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

    it "finds users with any role" do
      user.add_role(:manager, organization)
      users = organization.users_with_any_role(:admin, :editor)
      expect(users).to include(user)
    end

    it "finds users with all roles" do
      user.add_role(:manager, organization)
      expect(organization.users_with_all_roles(:admin, :manager)).to include(user)
      expect(organization.users_with_all_roles(:admin, :editor)).to be_empty
    end

    it "gets all users with roles" do
      expect(organization.users_with_roles).to include(user)
    end

    it "lists available roles" do
      expect(organization.available_roles).to include("admin")
    end

    it "counts users with role" do
      expect(organization.count_users_with_role(:admin)).to eq(1)
    end

    it "checks if resource has role" do
      expect(organization.has_role?(:admin)).to be true
    end

    it "gets applied roles" do
      expect(organization.applied_roles).to include(user.roles.first)
    end

    it "removes role from user via resource" do
      organization.remove_role_from_user(user, :admin)
      expect(user.has_role?(:admin, organization)).to be false
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
