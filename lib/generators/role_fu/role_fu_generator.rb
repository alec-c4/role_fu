# frozen_string_literal: true

require "rails/generators/active_record"

module RoleFu
  module Generators
    class RoleFuGenerator < ActiveRecord::Generators::Base
      source_root File.expand_path("templates", __dir__)

      argument :user_cname, type: :string, default: "User", banner: "User"

      def generate_models
        # Generate Role model
        template "role.rb.erb", "app/models/#{name.underscore}.rb"

        # Generate RoleAssignment model
        assignment_name = "#{name}Assignment"
        template "role_assignment.rb.erb", "app/models/#{assignment_name.underscore}.rb"
      end

      def copy_role_fu_migration
        migration_template "migration.rb.erb", "db/migrate/role_fu_create_#{table_name}.rb", migration_version: migration_version
      end

      def inject_role_fu_into_user_model
        user_path = "app/models/#{user_cname.underscore}.rb"
        if File.exist?(user_path)
          inject_into_class(user_path, user_cname.constantize) do
            "  include RoleFu::Roleable\n"
          end
        else
          print_notes "User model #{user_cname} not found at #{user_path}. Please add 'include RoleFu::Roleable' manually."
        end
      end

      private

      def migration_version
        "[#{Rails::VERSION::MAJOR}.#{Rails::VERSION::MINOR}]" if Rails::VERSION::MAJOR >= 5
      end
    end
  end
end
