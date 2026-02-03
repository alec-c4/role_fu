# frozen_string_literal: true

module RoleFu
  module Ability
    extend ActiveSupport::Concern

    def role_fu_can?(action, _resource = nil)
      role_fu_permissions.include?(action.to_s)
    end

    def role_fu_permissions
      return @_role_fu_permissions if defined?(@_role_fu_permissions) && @_role_fu_permissions

      permission_class = "Permission".safe_constantize
      return Set.new unless permission_class

      scope = roles
      scope = filter_expired(scope) if respond_to?(:filter_expired, true)

      @_role_fu_permissions = scope.joins(:permissions).pluck("permissions.action").map(&:to_s).to_set
    end
  end
end
