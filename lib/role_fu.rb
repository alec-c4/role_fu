# frozen_string_literal: true

require "active_support/concern"
require "active_support/core_ext/string/inflections"

require_relative "role_fu/version"
require_relative "role_fu/configuration"
require_relative "role_fu/role"
require_relative "role_fu/role_assignment"
require_relative "role_fu/roleable"
require_relative "role_fu/resourceable"

module RoleFu
  class Error < StandardError; end
  # Your code goes here...
end
