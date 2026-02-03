# frozen_string_literal: true

module RoleFu
  # Roleable concern - provides role management for User model
  module Roleable
    extend ActiveSupport::Concern

    included do
      has_many :role_assignments,
               class_name: RoleFu.configuration.role_assignment_class_name,
               dependent: :destroy
      has_many :roles,
               through: :role_assignments,
               class_name: RoleFu.configuration.role_class_name

      class_attribute :role_fu_callbacks, default: {}
    end

    module ClassMethods
      def role_fu_options(options = {})
        self.role_fu_callbacks = options.slice(:before_add, :after_add, :before_remove, :after_remove)
      end

      # Find users with a specific role
      # @param role_name [String, Symbol] The name of the role
      # @param resource [ActiveRecord::Base, Class, nil, :any] The resource
      # @return [ActiveRecord::Relation] Users with the role
      def with_role(role_name, resource = nil)
        role_table = RoleFu.role_class.table_name
        assignment_table = RoleFu.role_assignment_class.table_name
        
        query = joins(:roles).where(role_table => { name: role_name.to_s })

        if resource.nil?
          query.where(role_table => { resource_type: nil, resource_id: nil })
        elsif resource == :any
          query
        elsif resource.is_a?(Class)
          query.where(role_table => { resource_type: resource.to_s, resource_id: nil })
        else
          query.where(role_table => { resource_type: resource.class.name, resource_id: resource.id })
        end.distinct
      end

      # Find users without a specific role
      # @param role_name [String, Symbol] The name of the role
      # @param resource [ActiveRecord::Base, Class, nil, :any] The resource
      # @return [ActiveRecord::Relation] Users without the role
      def without_role(role_name, resource = nil)
        where.not(id: with_role(role_name, resource).select(:id))
      end

      # Find users with any of the specified roles
      # @param args [Array<String, Symbol, Hash>] Roles to check
      # @return [ActiveRecord::Relation] Users with any of the roles
      def with_any_role(*args)
        ids = []
        args.each do |arg|
          if arg.is_a?(Hash)
            ids += with_role(arg[:name], arg[:resource]).pluck(:id)
          else
            ids += with_role(arg).pluck(:id)
          end
        end
        where(id: ids.uniq)
      end

      # Find users with all of the specified roles
      # @param args [Array<String, Symbol, Hash>] Roles to check
      # @return [ActiveRecord::Relation] Users with all of the roles
      def with_all_roles(*args)
        ids = nil
        args.each do |arg|
          current_ids = if arg.is_a?(Hash)
                          with_role(arg[:name], arg[:resource]).pluck(:id)
                        else
                          with_role(arg).pluck(:id)
                        end
          ids = ids.nil? ? current_ids : ids & current_ids
          return none if ids.empty?
        end
        where(id: ids)
      end
    end

    # Add a role to the user
    # @param role_name [String, Symbol] The name of the role
    # @param resource [ActiveRecord::Base, Class, nil] The resource (organization, etc.) or nil for global role
    # @return [Role] The role that was added
    def add_role(role_name, resource = nil)
      role = find_or_create_role(role_name, resource)
      
      return role if roles.include?(role)

      run_role_fu_callback(:before_add, role)
      roles << role
      run_role_fu_callback(:after_add, role)
      
      role
    end
    alias_method :grant, :add_role

    # Remove a role from the user
    # @param role_name [String, Symbol] The name of the role
    # @param resource [ActiveRecord::Base, Class, nil] The resource or nil for global role
    # @return [Array<Role>] The roles that were removed
    def remove_role(role_name, resource = nil)
      roles_to_remove_relation = find_roles(role_name, resource)
      return [] if roles_to_remove_relation.empty?

      # Materialize before removing associations, because removing may trigger cleanup that deletes the role.
      removed_roles = roles_to_remove_relation.to_a

      removed_roles.each do |role|
        run_role_fu_callback(:before_remove, role)
        role_assignments.where(role_id: role.id).destroy_all
        run_role_fu_callback(:after_remove, role)
      end

      removed_roles
    end
    alias_method :revoke, :remove_role

    # Check if user has a specific role
    # @param role_name [String, Symbol] The name of the role
    # @param resource [ActiveRecord::Base, Class, nil, :any] The resource, nil for global, or :any for any resource
    # @return [Boolean] true if user has the role
    def has_role?(role_name, resource = nil)
      return false if role_name.nil?

      if resource == :any
        roles.exists?(name: role_name.to_s)
      else
        find_roles(role_name, resource).any?
      end
    end

    # Check if user has a specific role strictly (resource match must be exact, no globals overriding)
    # Note: In RoleFu, has_role? is already strict about resource matching unless :any is passed,
    # but this method explicitly bypasses any future global-fallback logic if we were to add it.
    # Included for API compatibility.
    # @param role_name [String, Symbol] The name of the role
    # @param resource [ActiveRecord::Base, Class, nil] The resource
    # @return [Boolean] true if user has the role strictly
    def has_strict_role?(role_name, resource = nil)
      has_role?(role_name, resource)
    end

    # Check if user only has this one role
    # @param role_name [String, Symbol] The name of the role
    # @param resource [ActiveRecord::Base, Class, nil] The resource
    # @return [Boolean] true if user has this role and no others
    def only_has_role?(role_name, resource = nil)
      has_role?(role_name, resource) && roles.count == 1
    end

    # Check for role using preloaded association to avoid N+1
    def has_cached_role?(role_name, resource = nil)
      role_name = role_name.to_s
      roles.to_a.any? do |role|
        next false unless role.name == role_name
        
        if resource == :any
          true
        elsif resource.is_a?(Class)
          role.resource_type == resource.to_s && role.resource_id.nil?
        elsif resource
          role.resource_type == resource.class.name && role.resource_id == resource.id
        else
          role.resource_type.nil? && role.resource_id.nil?
        end
      end
    end

    # Get all role names for this user
    # @param resource [ActiveRecord::Base, Class, nil] Filter by resource
    # @return [Array<String>] Array of role names
    def roles_name(resource = nil)
      if resource
        roles.where(resource: resource).pluck(:name)
      else
        roles.pluck(:name)
      end
    end

    # Check if user has only global roles (no resource-specific roles)
    # @return [Boolean] true if user has only global roles
    def has_only_global_roles?
      roles.where.not(resource_type: nil).empty?
    end

    # Check if user has any role (global or resource-specific)
    # @param resource [ActiveRecord::Base, Class, nil] Filter by resource
    # @return [Boolean] true if user has any role
    def has_any_role?(resource = nil)
      if resource
        roles.exists?(resource: resource)
      else
        roles.exists?
      end
    end

    # Check if user has all specified roles
    # @param role_names [Array<String, Symbol>] Array of role names
    # @param resource [ActiveRecord::Base, Class, nil] The resource
    # @return [Boolean] true if user has all roles
    def has_all_roles?(*role_names, resource: nil)
      role_names.flatten.all? { |role_name| has_role?(role_name, resource) }
    end

    # Check if user has any of the specified roles
    # @param role_names [Array<String, Symbol>] Array of role names
    # @param resource [ActiveRecord::Base, Class, nil] The resource
    # @return [Boolean] true if user has any of the roles
    def has_any_role_of?(*role_names, resource: nil)
      role_names.flatten.any? { |role_name| has_role?(role_name, resource) }
    end

    # Get all resources of a specific type where user has a role
    # @param resource_class [Class] The resource class (e.g., Organization)
    # @return [ActiveRecord::Relation] Relation of resources
    def resources(resource_class)
      resource_class.joins(:roles)
                    .merge(roles.where(resource_type: resource_class.name))
                    .distinct
    end

    private

    # Find or create a role
    # @param role_name [String, Symbol] The role name
    # @param resource [ActiveRecord::Base, Class, nil] The resource
    # @return [Role] The found or created role
    def find_or_create_role(role_name, resource)
      resource_type = resource_type_for(resource)
      resource_id = resource_id_for(resource)

      RoleFu.role_class.find_or_create_by(
        name: role_name.to_s,
        resource_type: resource_type,
        resource_id: resource_id
      )
    end

    # Find roles matching criteria
    # @param role_name [String, Symbol] The role name
    # @param resource [ActiveRecord::Base, Class, nil] The resource
    # @return [ActiveRecord::Relation] Relation of matching roles
    def find_roles(role_name, resource)
      query = roles.where(name: role_name.to_s)

      if resource.is_a?(Class)
        query.where(resource_type: resource.to_s, resource_id: nil)
      elsif resource
        query.where(resource_type: resource.class.name, resource_id: resource.id)
      else
        query.where(resource_type: nil, resource_id: nil)
      end
    end

    # Get resource type for a resource
    # @param resource [ActiveRecord::Base, Class, nil] The resource
    # @return [String, nil] The resource type
    def resource_type_for(resource)
      return nil if resource.nil?

      resource.is_a?(Class) ? resource.to_s : resource.class.name
    end

    # Get resource id for a resource
    # @param resource [ActiveRecord::Base, Class, nil] The resource
    # @return [Integer, nil] The resource id
    def resource_id_for(resource)
      return nil if resource.nil? || resource.is_a?(Class)

      resource.id
    end

    def run_role_fu_callback(callback_name, role)
      method_name = role_fu_callbacks[callback_name]
      return unless method_name
      
      if method_name.is_a?(Proc)
        instance_exec(role, &method_name)
      elsif respond_to?(method_name, true)
        send(method_name, role)
      end
    end
  end
end
