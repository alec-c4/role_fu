# frozen_string_literal: true

require "rails/generators/active_record"

module RoleFu
  module Generators
    class AuditGenerator < ActiveRecord::Generators::Base
      source_root File.expand_path("templates", __dir__)

      def create_migration
        migration_template "audit_migration.rb.erb", "db/migrate/role_fu_create_audits.rb", migration_version: migration_version
      end

      def create_model
        template "audit_model.rb.erb", "app/models/role_assignment_audit.rb"
      end

      private

      def migration_version
        "[#{Rails::VERSION::MAJOR}.#{Rails::VERSION::MINOR}]" if Rails::VERSION::MAJOR >= 5
      end
    end
  end
end
