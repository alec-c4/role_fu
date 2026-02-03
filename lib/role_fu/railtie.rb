# frozen_string_literal: true

require "rails/railtie"

module RoleFu
  class Railtie < Rails::Railtie
    rake_tasks do
      load "tasks/role_fu.rake"
    end
  end
end
