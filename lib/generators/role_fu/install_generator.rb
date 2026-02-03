# frozen_string_literal: true

require "rails/generators/base"

module RoleFu
  module Generators
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path("templates", __dir__)

      desc "Creates a RoleFu configuration file"

      def copy_initializer
        template "role_fu.rb", "config/initializers/role_fu.rb"
      end
    end
  end
end
