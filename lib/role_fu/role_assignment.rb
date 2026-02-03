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

      after_destroy :cleanup_orphaned_role
    end

    private

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
