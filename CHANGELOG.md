## [0.4.0] - 2026-02-08

### Added

- **Dynamic Shortcuts**:
    - Call methods like `user.is_admin?` or `user.is_manager?(org)` directly.
    - Configurable pattern (`config.dynamic_shortcuts_pattern`), defaults to `is_%{role}?`.
    - Custom patterns supported (e.g. `in_%{role}_group?`).
- **Enhanced Resourceable**:
    - Added `has_many :users, through: :roles` association for direct user access (e.g. `org.users`).
    - Added `users_grouped_by_role` to get a hash of users per role.
    - Added `destroy_role(role_name)` for bulk cleanup on a resource.
    - Added convenience methods/aliases: `users_with_roles`, `applied_roles`.
- **Generator**:
    - Updated install template to include new configuration options.

## [0.3.3] - 2026-02-07

### Fixed

- **UUID Support**: Generators now automatically detect and use UUIDs for primary and foreign keys if enabled in the application or model configuration.

## [0.3.1] - 2026-02-06

### Improved

- **Generator Flexibility**: `role_fu` generator now supports 0, 1, or 2 arguments for easier setup (e.g., `rails g role_fu Group Account`).
- **Documentation**: Enhanced CLI help output for all generators, placing usage examples and descriptions prominently above options.
- **Audit & Ability Generators**: Explicitly documented the `NAME` argument in help banners.

## [0.3.0] - 2026-02-03

### BREAKING CHANGES

- **Drop Rails 7.0 and 7.1 support**: Minimum required Rails version is now 7.2+
  - Rails 7.0 and 7.1 require `sqlite3 ~> 1.4`, which conflicts with `sqlite3 ~> 2.0`
  - Rails 7.2+ supports `sqlite3 >= 1.6.6`, ensuring compatibility with modern sqlite3 versions
  - Updated `activerecord` dependency from `>= 7.0` to `>= 7.2`
  - Removed Rails 7.0 and 7.1 from CI test matrix

## [0.2.0] - 2026-02-03

### Added

- **Temporal Roles**: Support for role expiration (`expires_at`) and automatic filtering.
- **Audit Logging**: Built-in generator for audit trails (`RoleAssignmentAudit`) and actor tracking (`RoleFu.with_actor`).
- **Role Abilities**: Granular permissions system with `Permission` model and `role_fu_can?` helper.
- **Metadata**: Support for attaching arbitrary JSON metadata to role assignments.
- **Adapters**: Seamless integration with **Pundit** and **CanCanCan**.
- **Permissive Mode**: Configuration option `global_roles_override` to match Rolify behavior.
- **Cleanup Automation**: `rake role_fu:cleanup` task and ActiveJob generator for expired roles.
- **Custom Aliases**: `role_fu_alias` to generate domain-specific methods (e.g., `add_group`, `in_group`).

## [0.1.0] - 2026-02-03

- Initial release: modern role management for Rails with explicit models and N+1 prevention.
