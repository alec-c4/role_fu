# frozen_string_literal: true

module RoleFu
  # Module for the RoleAssignment model
  module RoleAssignment
    extend ActiveSupport::Concern

    included do
      belongs_to :user, class_name: RoleFu.configuration.user_class_name
      belongs_to :role, class_name: RoleFu.configuration.role_class_name

      scope :global_roles, -> { joins(:role).where(RoleFu.role_class.table_name => {resource_type: nil, resource_id: nil}) }
      scope :resource_specific, -> { joins(:role).where.not(RoleFu.role_class.table_name => {resource_type: nil}) }

      after_create :audit_create
      after_update :audit_update
      after_destroy :audit_destroy

      after_destroy :cleanup_orphaned_role
    end

    private

    def audit_create
      audit_log("INSERT")
    end

    def audit_update
      audit_log("UPDATE")
    end

    def audit_destroy
      audit_log("DELETE")
    end

    def audit_log(operation)
      # Only audit if the Audit model exists
      audit_class = "RoleAssignmentAudit".safe_constantize
      return unless audit_class

      actor = RoleFu.current_actor

      audit_class.create(
        role_assignment_id: id,
        user_id: user_id,
        role_id: role_id,
        operation: operation,
        whodunnit: actor.try(:id) || actor.to_s,
        meta_snapshot: try(:meta),
        expires_at_snapshot: try(:expires_at)
      )
    rescue
      # Fail silently or log error? Logging is safer to avoid breaking the main flow.
      # defined?(Rails) ? Rails.logger.error("RoleFu Audit Error: #{e.message}") : puts("RoleFu Audit Error: #{e.message}")
    end

    def cleanup_orphaned_role
      # If this record is being destroyed as part of role destruction,
      # do not try to destroy the same role again.
      return if destroyed_by_association&.active_record == RoleFu.role_class

      # Delete role if it has no more users assigned
      return if role.destroyed?

      role.destroy if role.role_assignments.none?
    end
  end
end
