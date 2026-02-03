# frozen_string_literal: true

require "simplecov"
SimpleCov.start do
  add_filter "/spec/"
  add_group "Library", "lib"
end

require "role_fu"
require "active_record"

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.before(:suite) do
    ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")

    ActiveRecord::Schema.define do
      self.verbose = false

      create_table :users, force: true do |t|
        t.string :name
      end

      create_table :roles, force: true do |t|
        t.string :name
        t.string :resource_type
        t.integer :resource_id
        t.timestamps
      end

      create_table :role_assignments, force: true do |t|
        t.integer :user_id
        t.integer :role_id
        t.datetime :expires_at
        t.string :meta # using string for jsonb emulation in sqlite
        t.timestamps
      end

      create_table :role_assignment_audits, force: true do |t|
        t.integer :user_id
        t.integer :role_id
        t.integer :role_assignment_id
        t.string :operation
        t.string :whodunnit
        t.string :meta_snapshot
        t.datetime :expires_at_snapshot
        t.timestamps
      end

      create_table :permissions, force: true do |t|
        t.integer :role_id
        t.string :action
        t.string :conditions
        t.timestamps
      end

      create_table :organizations, force: true do |t|
        t.string :name
      end
    end
  end
end

class User < ActiveRecord::Base
  include RoleFu::Roleable
  include RoleFu::Ability

  role_fu_options before_add: :log_before_add, after_add: :log_after_add

  attr_accessor :callback_log

  def log_before_add(role)
    (@callback_log ||= []) << "before_add_#{role.name}"
  end

  def log_after_add(role)
    (@callback_log ||= []) << "after_add_#{role.name}"
  end
end

class Role < ActiveRecord::Base
  include RoleFu::Role

  has_many :permissions, dependent: :destroy
end

class Permission < ActiveRecord::Base
  include RoleFu::Permission
end

class RoleAssignment < ActiveRecord::Base
  include RoleFu::RoleAssignment
end

class RoleAssignmentAudit < ActiveRecord::Base
end

class Organization < ActiveRecord::Base
  include RoleFu::Resourceable
end
