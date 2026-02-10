# frozen_string_literal: true

module RoleFu
  class Configuration
    attr_accessor :user_class_name, :role_class_name, :role_assignment_class_name, :global_roles_override
    attr_reader :dynamic_shortcuts_pattern, :dynamic_shortcuts_regex

    def initialize
      @user_class_name = "User"
      @role_class_name = "Role"
      @role_assignment_class_name = "RoleAssignment"
      @global_roles_override = false
      self.dynamic_shortcuts_pattern = "is_%{role}?"
    end

    def dynamic_shortcuts_pattern=(pattern)
      @dynamic_shortcuts_pattern = pattern
      if pattern.nil? || pattern.strip.empty?
        @dynamic_shortcuts_regex = nil
      else
        parts = pattern.split("%{role}", -1)
        regex_string = "^#{parts.map { |part| Regexp.escape(part) }.join("(?<role>.+)")}$"
        @dynamic_shortcuts_regex = Regexp.new(regex_string)
      end
    end
  end

  class << self
    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration)
    end

    def user_class
      configuration.user_class_name.constantize
    end

    def role_class
      configuration.role_class_name.constantize
    end

    def role_assignment_class
      configuration.role_assignment_class_name.constantize
    end
  end
end
