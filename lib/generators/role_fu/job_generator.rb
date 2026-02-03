# frozen_string_literal: true

require "rails/generators/base"

module RoleFu
  module Generators
    class JobGenerator < Rails::Generators::Base
      source_root File.expand_path("templates", __dir__)

      def create_job
        template "cleanup_job.rb.erb", "app/jobs/role_fu/cleanup_job.rb"
      end
    end
  end
end
