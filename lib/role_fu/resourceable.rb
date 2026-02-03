# frozen_string_literal: true

module RoleFu
  module Resourceable
    extend ActiveSupport::Concern

    included do
      has_many :roles,
        as: :resource,
        dependent: :destroy,
        class_name: RoleFu.configuration.role_class_name
    end

    module ClassMethods
      def find_roles(role_name = nil, user = nil)
        query = RoleFu.role_class.where(resource_type: name)
        query = query.where(name: role_name.to_s) if role_name
        query = query.joins(:users).where(RoleFu.user_class.table_name => {id: user.id}) if user
        query
      end

      def with_role(role_name, user = nil)
        role_table = RoleFu.role_class.table_name
        query = joins(:roles).where(role_table => {name: role_name.to_s})
        query = query.joins(roles: :users).where(RoleFu.user_class.table_name => {id: user.id}) if user
        query.distinct
      end

      def without_role(role_name, user = nil)
        where.not(id: with_role(role_name, user).select(:id))
      end

      # Dynamically create aliases for role methods
      # @param name [Symbol, String] The alias name (e.g. :group)
      def role_fu_alias(name)
        singular = name.to_s.singularize
        plural = name.to_s.pluralize

        # Class methods
        singleton_class.class_eval do
          alias_method "find_#{plural}", :find_roles
          alias_method "with_#{singular}", :with_role
          alias_method "without_#{singular}", :without_role
        end

        # Instance methods
        alias_method "users_with_#{singular}", :users_with_role
        alias_method "users_with_any_#{singular}", :users_with_any_role
        alias_method "users_with_all_#{plural}", :users_with_all_roles
        alias_method "users_with_#{plural}", :users_with_roles
        alias_method "available_#{plural}", :available_roles
        alias_method "has_#{singular}?", :has_role?
        alias_method "count_users_with_#{singular}", :count_users_with_role
        alias_method "user_has_#{singular}?", :user_has_role?
        alias_method "add_#{singular}_to_user", :add_role_to_user
        alias_method "remove_#{singular}_from_user", :remove_role_from_user
      end
    end

    def applied_roles
      roles
    end

    def users_with_role(role_name)
      role_table = RoleFu.role_class.table_name
      RoleFu.user_class.joins(:roles)
        .where(role_table => {name: role_name.to_s, resource_type: self.class.name, resource_id: id})
        .distinct
    end

    def users_with_any_role(*role_names)
      role_table = RoleFu.role_class.table_name
      RoleFu.user_class.joins(:roles)
        .where(role_table => {name: role_names.flatten.map(&:to_s), resource_type: self.class.name, resource_id: id})
        .distinct
    end

    def users_with_all_roles(*role_names)
      role_names = role_names.flatten.map(&:to_s)
      role_table = RoleFu.role_class.table_name
      user_table = RoleFu.user_class.table_name
      user_pk = RoleFu.user_class.primary_key

      RoleFu.user_class.joins(:roles)
        .where(role_table => {name: role_names, resource_type: self.class.name, resource_id: id})
        .group("#{user_table}.#{user_pk}")
        .having("COUNT(DISTINCT #{role_table}.name) = ?", role_names.size)
        .distinct
    end

    def users_with_roles
      role_table = RoleFu.role_class.table_name
      RoleFu.user_class.joins(:roles)
        .where(role_table => {resource_type: self.class.name, resource_id: id})
        .distinct
    end

    def available_roles
      roles.pluck(:name).uniq
    end

    def has_role?(role_name)
      roles.exists?(name: role_name.to_s)
    end

    def count_users_with_role(role_name)
      users_with_role(role_name).count
    end

    def user_has_role?(user, role_name)
      user&.has_role?(role_name, self) || false
    end

    def add_role_to_user(user, role_name)
      user.add_role(role_name, self)
    end

    def remove_role_from_user(user, role_name)
      user.remove_role(role_name, self)
    end
  end
end
