# frozen_string_literal: true

module RoleFu
  # Module for the Role model
  module Role
    extend ActiveSupport::Concern

    included do
      has_many :role_assignments,
               class_name: RoleFu.configuration.role_assignment_class_name,
               dependent: :destroy
      has_many :users,
               through: :role_assignments,
               class_name: RoleFu.configuration.user_class_name

      belongs_to :resource, polymorphic: true, optional: true

      validates :name, presence: true, uniqueness: { scope: [:resource_type, :resource_id] }
    end
  end
end
