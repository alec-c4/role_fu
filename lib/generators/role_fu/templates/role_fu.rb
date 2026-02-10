# frozen_string_literal: true

RoleFu.configure do |config|
  # The class name of your User model
  # config.user_class_name = "User"

  # The class name of your Role model
  # config.role_class_name = "Role"

  # The class name of your RoleAssignment model
  # config.role_assignment_class_name = "RoleAssignment"

  # Enable Rolify-style permissive checks (Global roles override resource checks)
  # config.global_roles_override = false

  # Enable dynamic shortcuts (e.g. user.is_admin?)
  # Default is "is_%{role}?". Set to nil to disable.
  # config.dynamic_shortcuts_pattern = "is_%{role}?"
end
