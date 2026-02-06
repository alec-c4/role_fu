# frozen_string_literal: true

require "rails/generators/active_record"

module RoleFu
  module Generators
    class AbilitiesGenerator < ActiveRecord::Generators::Base
      source_root File.expand_path("templates", __dir__)

      argument :name, type: :string, default: "abilities"

      def self.banner
        "bin/rails generate role_fu:abilities [NAME] [options]\n\n" \
        "Generates the permission model and migration.\n" \
        "  NAME is the name of the permission model (default: 'abilities')."
      end

      desc ""

      def generate_permission_model
        template "permission.rb.erb", "app/models/permission.rb"
      end

      def create_abilities_migration
        migration_template "abilities_migration.rb.erb", "db/migrate/role_fu_create_permissions.rb", migration_version: migration_version
      end

      def inject_into_role_model
        role_cname = RoleFu.configuration.role_class_name
        path = "app/models/#{role_cname.underscore}.rb"

        if File.exist?(path)
          inject_into_class(path, role_cname.constantize) do
            "  has_many :permissions, dependent: :destroy\n"
          end
        else
          say "Role model #{role_cname} not found. Please add 'has_many :permissions' manually."
        end
      end

      def inject_into_user_model
        user_cname = RoleFu.configuration.user_class_name
        path = "app/models/#{user_cname.underscore}.rb"

        if File.exist?(path)
          inject_into_class(path, user_cname.constantize) do
            "  include RoleFu::Ability\n"
          end
        else
          say "User model #{user_cname} not found. Please add 'include RoleFu::Ability' manually."
        end
      end

      private

      def migration_version
        "[#{Rails::VERSION::MAJOR}.#{Rails::VERSION::MINOR}]" if Rails::VERSION::MAJOR >= 5
      end
    end
  end
end
