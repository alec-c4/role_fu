# frozen_string_literal: true

require "rails/generators/active_record"

module RoleFu
  module Generators
    class AuditGenerator < ActiveRecord::Generators::Base
      source_root File.expand_path("templates", __dir__)

      argument :name, type: :string, default: "audit"

      def self.banner
        "bin/rails generate role_fu:audit [NAME] [options]\n\n" \
        "Generates the audit model and migration.\n" \
        "  NAME is the name of the audit model (default: 'audit')."
      end

      desc "" # Empty desc to avoid duplication at the bottom

      def create_audit_migration
        migration_template "audit_migration.rb.erb", "db/migrate/role_fu_create_audits.rb", migration_version: migration_version, uuid_enabled: uuid_enabled?
      end

      def create_model
        template "audit_model.rb.erb", "app/models/role_assignment_audit.rb"
      end

      private

      def migration_version
        "[#{Rails::VERSION::MAJOR}.#{Rails::VERSION::MINOR}]" if Rails::VERSION::MAJOR >= 5
      end

      def uuid_enabled?
        options[:primary_key_type] == "uuid" ||
          Rails.configuration.generators.options.dig(:active_record, :primary_key_type) == :uuid ||
          user_has_uuid_pk?
      end

      def user_has_uuid_pk?
        user_cname = RoleFu.configuration.user_class_name || "User"
        klass = user_cname.safe_constantize
        return false unless klass&.table_exists?
        klass.columns_hash[klass.primary_key]&.type == :uuid
      end
    end
  end
end
