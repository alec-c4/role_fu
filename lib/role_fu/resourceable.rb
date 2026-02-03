# frozen_string_literal: true

module RoleFu
  # Resourceable concern - provides resource management for models with roles
  module Resourceable
    extend ActiveSupport::Concern

    included do
      has_many :roles,
               as: :resource,
               dependent: :destroy,
               class_name: RoleFu.configuration.role_class_name
    end

    module ClassMethods
      # Find roles defined on any instance of this resource class
      # @param role_name [String, Symbol, nil] Filter by role name
      # @param user [User, nil] Filter by user
      # @return [ActiveRecord::Relation] Roles
      def find_roles(role_name = nil, user = nil)
        role_table = RoleFu.role_class.table_name
        query = RoleFu.role_class.where(resource_type: name)
        query = query.where(name: role_name.to_s) if role_name
        query = query.joins(:users).where(RoleFu.user_class.table_name => { id: user.id }) if user
        query
      end

      # Find resources that have a specific role applied (to a user)
      # @param role_name [String, Symbol] The role name
      # @param user [User, nil] Filter by specific user having the role
      # @return [ActiveRecord::Relation] Resources
      def with_role(role_name, user = nil)
        role_table = RoleFu.role_class.table_name
        
        query = joins(:roles).where(role_table => { name: role_name.to_s })
        
        if user
          query = query.joins(roles: :users).where(RoleFu.user_class.table_name => { id: user.id })
        end
        
        query.distinct
      end
      
      # Find resources that do NOT have a specific role applied
      # @param role_name [String, Symbol] The role name
      # @param user [User, nil] Filter by user
      # @return [ActiveRecord::Relation] Resources
      def without_role(role_name, user = nil)
        where.not(id: with_role(role_name, user).select(:id))
      end
    end

    # Get roles applied to this resource instance (plus global class-level roles if any - though RoleFu focuses on instance roles)
    # @return [ActiveRecord::Relation] Roles
    def applied_roles
      roles
    end

    # Get users with a specific role on this resource
    # @param role_name [String, Symbol] The role name
    # @return [ActiveRecord::Relation] Relation of users
    def users_with_role(role_name)
      role_table = RoleFu.role_class.table_name
      user_class.joins(:roles)
                .where(role_table => { name: role_name.to_s, resource_type: self.class.name, resource_id: id })
                .distinct
    end

    # Get users with any role on this resource
    # @param role_names [Array<String, Symbol>] Array of role names
    # @return [ActiveRecord::Relation] Relation of users
    def users_with_any_role(*role_names)
      role_table = RoleFu.role_class.table_name
      user_class.joins(:roles)
                .where(role_table => { name: role_names.flatten.map(&:to_s), resource_type: self.class.name, resource_id: id })
                .distinct
    end

    # Get users with all specified roles on this resource
    # @param role_names [Array<String, Symbol>] Array of role names
    # @return [Array<User>] Array of users
    def users_with_all_roles(*role_names)
      role_names = role_names.flatten.map(&:to_s)
      role_table = RoleFu.role_class.table_name
      
      user_class.joins(:roles)
                .where(role_table => { name: role_names, resource_type: self.class.name, resource_id: id })
                .group("#{user_class.table_name}.#{user_class.primary_key}")
                .having("COUNT(DISTINCT #{role_table}.name) = ?", role_names.size)
                .distinct
    end

    # Get all users with any role on this resource
    # @return [ActiveRecord::Relation] Relation of users
    def users_with_roles
      role_table = RoleFu.role_class.table_name
      user_class.joins(:roles)
                .where(role_table => { resource_type: self.class.name, resource_id: id })
                .distinct
    end

    # Get all role names defined for this resource
    # @return [Array<String>] Array of role names
    def available_roles
      roles.pluck(:name).uniq
    end

    # Check if resource has any users with a specific role
    # @param role_name [String, Symbol] The role name
    # @return [Boolean] true if any user has this role
    def has_role?(role_name)
      roles.exists?(name: role_name.to_s)
    end

    # Count users with a specific role
    # @param role_name [String, Symbol] The role name
    # @return [Integer] Number of users
    def count_users_with_role(role_name)
      users_with_role(role_name).count
    end

    # Check if a specific user has a role on this resource
    # @param user [User] The user
    # @param role_name [String, Symbol] The role name
    # @return [Boolean] true if user has the role
    def user_has_role?(user, role_name)
      return false if user.nil?

      user.has_role?(role_name, self)
    end

    # Add a role to a user on this resource
    # @param user [User] The user
    # @param role_name [String, Symbol] The role name
    # @return [Role] The role
    def add_role_to_user(user, role_name)
      user.add_role(role_name, self)
    end

    # Remove a role from a user on this resource
    # @param user [User] The user
    # @param role_name [String, Symbol] The role name
    # @return [Array<Role>] The removed roles
    def remove_role_from_user(user, role_name)
      user.remove_role(role_name, self)
    end

    private

    # Get the User class
    # @return [Class] User class
    def user_class
      RoleFu.user_class
    end
  end
end
