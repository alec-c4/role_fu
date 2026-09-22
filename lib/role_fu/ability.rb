# frozen_string_literal: true

module RoleFu
  module Ability
    extend ActiveSupport::Concern

    # @param action [String, Symbol] e.g. "posts.update"
    # @param field [String, Symbol, nil] restrict the check to a single attribute
    #   (e.g. :description). A permission granted with field: nil is a wildcard
    #   that satisfies any field-scoped check for the same action.
    def role_fu_can?(action, _resource = nil, field: nil)
      fields = role_fu_permission_fields(action)
      return false if fields.nil?

      field.nil? || fields.include?(nil) || fields.include?(field.to_s)
    end

    # Fields explicitly granted for `action`.
    # Returns :all when the action was granted without a field restriction,
    # [] when the action isn't granted at all, or the explicit field list otherwise.
    def role_fu_permitted_fields(action)
      fields = role_fu_permission_fields(action)
      return [] if fields.nil?
      return :all if fields.include?(nil)

      fields.to_a
    end

    def role_fu_permissions
      role_fu_permissions_index.keys.to_set
    end

    private

    def role_fu_permission_fields(action)
      role_fu_permissions_index[action.to_s]
    end

    def role_fu_permissions_index
      return @_role_fu_permissions if defined?(@_role_fu_permissions) && @_role_fu_permissions

      permission_class = "Permission".safe_constantize
      return (@_role_fu_permissions = {}) unless permission_class

      scope = roles
      scope = filter_expired(scope) if respond_to?(:filter_expired, true)

      has_field_column = permission_class.column_names.include?("field")
      columns = has_field_column ? %w[permissions.action permissions.field] : %w[permissions.action]
      rows = scope.joins(:permissions).pluck(*columns)

      @_role_fu_permissions = rows.each_with_object({}) do |row, index|
        action, field = has_field_column ? row : [row, nil]
        (index[action.to_s] ||= Set.new) << field
      end
    end
  end
end
