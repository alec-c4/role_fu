# frozen_string_literal: true

require "spec_helper"

RSpec.describe RoleFu do
  describe "Dynamic Shortcuts" do
    let(:user) { User.create(name: "Shortcut User") }
    let(:organization) { Organization.create(name: "Shortcut Org") }

    after do
      described_class.configure do |config|
        config.dynamic_shortcuts_pattern = "is_%{role}?" # Reset to default
      end
    end

    context "with default configuration (is_%{role}?)" do
      before do
        described_class.configure { |c| c.dynamic_shortcuts_pattern = "is_%{role}?" }
      end

      it "responds to dynamic methods" do
        expect(user.respond_to?(:is_admin?)).to be true
        expect(user.respond_to?(:is_super_admin?)).to be true
        expect(user.respond_to?(:random_method)).to be false
      end

      it "checks global role" do
        user.add_role(:admin)
        expect(user.is_admin?).to be true
        expect(user.is_editor?).to be false
      end

      it "checks resource role" do
        user.add_role(:manager, organization)
        expect(user.is_manager?(organization)).to be true
        expect(user.is_manager?).to be false # strict check depending on implementation, has_role?(:manager) checks global or resource?
        # user.has_role?(:manager) checks if they have a global role :manager.
        # If they have :manager on Org, has_role?(:manager) returns false unless global_roles_override is set.
      end

      it "handles underscores in role names" do
        user.add_role(:super_admin)
        expect(user.is_super_admin?).to be true
      end
    end

    context "with custom configuration (in_%{role}_group?)" do
      before do
        described_class.configure { |c| c.dynamic_shortcuts_pattern = "in_%{role}_group?" }
      end

      it "responds to custom pattern" do
        expect(user.respond_to?(:in_admin_group?)).to be true
        expect(user.respond_to?(:is_admin?)).to be false
      end

      it "checks role using custom pattern" do
        user.add_role(:admin)
        expect(user.in_admin_group?).to be true
      end

      it "checks resource role using custom pattern" do
        user.add_role(:manager, organization)
        expect(user.in_manager_group?(organization)).to be true
        expect(user.in_manager_group?).to be false
      end
    end

    context "when disabled" do
      before do
        described_class.configure { |c| c.dynamic_shortcuts_pattern = nil }
      end

      it "does not respond to dynamic methods" do
        expect(user.respond_to?(:is_admin?)).to be false
      end

      it "raises NoMethodError" do
        user.add_role(:admin)
        expect { user.is_admin? }.to raise_error(NoMethodError)
      end
    end
  end
end
