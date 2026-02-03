# frozen_string_literal: true

require "active_support/concern"
require "active_support/core_ext/string/inflections"

require_relative "role_fu/version"
require_relative "role_fu/configuration"
require_relative "role_fu/role"
require_relative "role_fu/role_assignment"
require_relative "role_fu/roleable"
require_relative "role_fu/resourceable"
require_relative "role_fu/permission"
require_relative "role_fu/ability"
require_relative "role_fu/cleanup"
require_relative "role_fu/adapters/cancancan"
require_relative "role_fu/adapters/pundit"
require_relative "role_fu/railtie" if defined?(Rails)

module RoleFu
  class Error < StandardError; end

  class << self
    def with_actor(actor)
      Thread.current[:role_fu_actor] = actor
      yield
    ensure
      Thread.current[:role_fu_actor] = nil
    end

    def current_actor
      Thread.current[:role_fu_actor]
    end
  end
end
