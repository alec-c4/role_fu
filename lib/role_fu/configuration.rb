# frozen_string_literal: true

module RoleFu
  class Configuration
    attr_accessor :user_class_name, :role_class_name, :role_assignment_class_name

    def initialize
      @user_class_name = "User"
      @role_class_name = "Role"
      @role_assignment_class_name = "RoleAssignment"
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
