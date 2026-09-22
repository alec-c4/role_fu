# frozen_string_literal: true

require "rails/generators/active_record"

module RoleFu
  module Generators
    # Run after bumping the role_fu gem version. Does not track "which
    # version you upgraded from" - there's nowhere reliable to read that from
    # (Gemfile.lock only ever has the current version). Instead it inspects
    # the actual schema/config already installed and generates whatever is
    # missing, so it's safe to run regardless of how many versions you skipped,
    # and safe to run again if nothing changed.
    class UpgradeGenerator < ActiveRecord::Generators::Base
      source_root File.expand_path("templates", __dir__)

      argument :name, type: :string, default: "upgrade"

      def self.banner
        "bin/rails generate role_fu:upgrade\n\n" \
        "Detects which optional role_fu columns/config are missing for your\n" \
        "installed models and generates the migrations needed to catch up."
      end

      desc ""

      def run_upgrade_checks
        applied = upgrade_checks.count { |check| send(check) }

        say "role_fu is already up to date - nothing to generate.", :green if applied.zero?
      end

      private

      # Each check returns true when it generated something or has a warning
      # to report. Add new entries here as future optional columns/config land.
      def upgrade_checks
        [:check_permissions_field, :check_denormalized_role_names]
      end

      def check_permissions_field
        return false unless table_exists?(:permissions)
        return false if column_exists?(:permissions, :field)

        say "Adding missing 'field' column to permissions (see README: Field-level granularity)", :yellow
        migration_template "upgrade_permissions_field_migration.rb.erb", "db/migrate/role_fu_add_field_to_permissions.rb"
        true
      end

      # Not auto-fixed: blindly renaming could collide two existing roles
      # (e.g. "Admin" and "admin" both already present with their own
      # role_assignments) into one, which needs a human to decide how to
      # merge rather than a migration silently doing it.
      def check_denormalized_role_names
        role_class = RoleFu.configuration.role_class_name.safe_constantize
        return false unless role_class&.table_exists?

        denormalized = role_class.pluck(:name).any? { |name| name != RoleFu.normalize_role_name(name) }
        return false unless denormalized

        say "Found role names that don't match RoleFu's normalized format (e.g. \"Admin\" vs \"admin\").", :yellow
        say "Not fixed automatically - two differently-cased roles may already coexist and need a human merge decision.", :yellow
        say "Review, then backfill e.g.: UPDATE #{role_class.table_name} SET name = LOWER(name) WHERE name != LOWER(name)", :yellow
        true
      end

      def table_exists?(name)
        ActiveRecord::Base.connection.table_exists?(name.to_s)
      rescue
        false
      end

      def column_exists?(table, column)
        ActiveRecord::Base.connection.column_exists?(table.to_s, column)
      rescue
        false
      end

      def migration_version
        "[#{Rails::VERSION::MAJOR}.#{Rails::VERSION::MINOR}]" if Rails::VERSION::MAJOR >= 5
      end
    end
  end
end
