## [Unreleased]

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
