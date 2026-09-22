# frozen_string_literal: true

# Minimal double standing in for CanCan::Ability — this gem does not depend
# on cancancan, so we only verify that the adapter calls `can` with the
# arguments CanCanCan itself expects (including its native attribute
# restriction form: `can :update, Post, :title`).
class FakeCanCanAbility
  include RoleFu::Adapters::CanCanCan

  Rule = Struct.new(:action, :subject, :fields)

  attr_reader :rules

  def initialize(user)
    @rules = []
    role_fu_load_permissions!(user)
  end

  def can(action, subject, *fields)
    rules << Rule.new(action, subject, fields)
  end
end

RSpec.describe RoleFu::Adapters::CanCanCan do
  let(:user) { User.create(name: "Test User") }

  it "grants unrestricted access for actions without a field constraint" do
    role = user.add_role(:cancan_editor_1)
    role.permissions.create(action: "organizations.update")

    ability = FakeCanCanAbility.new(user)

    rule = ability.rules.find { |r| r.subject == Organization }
    expect(rule.action).to eq(:update)
    expect(rule.fields).to eq([])
  end

  it "maps field-scoped permissions onto CanCanCan's own attribute restriction" do
    role = user.add_role(:cancan_editor_2)
    role.permissions.create(action: "organizations.update", field: "name")

    ability = FakeCanCanAbility.new(user)

    rule = ability.rules.find { |r| r.subject == Organization }
    expect(rule.action).to eq(:update)
    expect(rule.fields).to eq([:name])
  end

  it "falls back to a symbol subject when the resource can't be constantized" do
    role = user.add_role(:cancan_editor_3)
    role.permissions.create(action: "widgets.destroy")

    ability = FakeCanCanAbility.new(user)

    rule = ability.rules.find { |r| r.subject == :widgets }
    expect(rule.action).to eq(:destroy)
  end
end
