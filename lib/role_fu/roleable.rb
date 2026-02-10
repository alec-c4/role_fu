# frozen_string_literal: true

module RoleFu
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

      def with_role(role_name, resource = nil)
        role_table = RoleFu.role_class.table_name
        assignment_table = RoleFu.role_assignment_class.table_name

        query = joins(:roles).where(role_table => {name: role_name.to_s})

        if RoleFu.role_assignment_class.column_names.include?("expires_at")
          query = query.where("#{assignment_table}.expires_at IS NULL OR #{assignment_table}.expires_at > ?", Time.current)
        end

        if resource.nil?
          query.where(role_table => {resource_type: nil, resource_id: nil})
        elsif resource == :any
          query
        elsif resource.is_a?(Class)
          query.where(role_table => {resource_type: resource.to_s, resource_id: nil})
        else
          query.where(role_table => {resource_type: resource.class.name, resource_id: resource.id})
        end.distinct
      end

      def without_role(role_name, resource = nil)
        where.not(id: with_role(role_name, resource).select(:id))
      end

      def with_any_role(*args)
        ids = args.flat_map do |arg|
          arg.is_a?(Hash) ? with_role(arg[:name], arg[:resource]).pluck(:id) : with_role(arg).pluck(:id)
        end
        where(id: ids.uniq)
      end

      def with_all_roles(*args)
        ids = nil
        args.each do |arg|
          current_ids = arg.is_a?(Hash) ? with_role(arg[:name], arg[:resource]).pluck(:id) : with_role(arg).pluck(:id)
          ids = ids.nil? ? current_ids : ids & current_ids
          return none if ids.empty?
        end
        where(id: ids)
      end

      # Dynamically create aliases for role methods
      # @param name [Symbol, String] The alias name (e.g. :group)
      # @example
      #   role_fu_alias :group
      #   # Creates: add_group, remove_group, has_group?, with_group, in_group, etc.
      def role_fu_alias(name)
        singular = name.to_s.singularize
        plural = name.to_s.pluralize

        # Instance methods
        alias_method "add_#{singular}", :add_role
        alias_method "remove_#{singular}", :remove_role
        alias_method "has_#{singular}?", :has_role?
        alias_method "only_has_#{singular}?", :only_has_role?
        alias_method "has_any_#{singular}?", :has_any_role?
        alias_method "has_all_#{plural}?", :has_all_roles?
        alias_method "#{plural}_name", :roles_name

        # Class methods (Scopes)
        singleton_class.class_eval do
          alias_method "with_#{singular}", :with_role
          alias_method "without_#{singular}", :without_role
          alias_method "with_any_#{singular}", :with_any_role
          alias_method "with_all_#{plural}", :with_all_roles

          # Additional natural aliases
          alias_method "in_#{singular}", :with_role
          alias_method "not_in_#{singular}", :without_role
        end
      end
    end

    def add_role(role_name, resource = nil, expires_at: nil, meta: nil)
      role = find_or_create_role(role_name, resource)
      existing_assignment = role_assignments.find_by(role: role)

      if existing_assignment
        if expires_at || meta
          updates = {}
          updates[:expires_at] = expires_at if expires_at
          updates[:meta] = meta if meta
          existing_assignment.update(updates)
        end
        return role
      end

      run_role_fu_callback(:before_add, role)
      role_assignments.create!(role: role, expires_at: expires_at, meta: meta)
      roles.reload
      run_role_fu_callback(:after_add, role)

      role
    end
    alias_method :grant, :add_role

    def remove_role(role_name, resource = nil)
      roles_to_remove_relation = find_roles(role_name, resource)
      return [] if roles_to_remove_relation.empty?

      removed_roles = roles_to_remove_relation.to_a
      removed_roles.each do |role|
        run_role_fu_callback(:before_remove, role)
        role_assignments.where(role_id: role.id).destroy_all
        run_role_fu_callback(:after_remove, role)
      end

      removed_roles
    end
    alias_method :revoke, :remove_role

    def has_role?(role_name, resource = nil)
      return false if role_name.nil?

      if resource == :any
        filter_expired(roles.where(name: role_name.to_s)).exists?
      else
        return true if filter_expired(find_roles(role_name, resource)).any?

        if RoleFu.configuration.global_roles_override && resource && !resource.is_a?(Class)
          return filter_expired(find_roles(role_name, nil)).any?
        end

        false
      end
    end

    def has_strict_role?(role_name, resource = nil)
      filter_expired(find_roles(role_name, resource)).any?
    end

    def only_has_role?(role_name, resource = nil)
      has_role?(role_name, resource) && filter_expired(roles).count == 1
    end

    def has_cached_role?(role_name, resource = nil)
      role_name = role_name.to_s
      roles.to_a.any? do |role|
        next false unless role.name == role_name

        assignment = role_assignments.find { |ra| ra.role_id == role.id }
        next false if assignment&.respond_to?(:expires_at) && assignment.expires_at && assignment.expires_at <= Time.current

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

    def roles_name(resource = nil)
      scope = resource ? roles.where(resource: resource) : roles
      filter_expired(scope).pluck(:name)
    end

    def has_only_global_roles?
      filter_expired(roles).where.not(resource_type: nil).empty?
    end

    def has_any_role?(resource = nil)
      scope = resource ? roles.where(resource: resource) : roles
      filter_expired(scope).exists?
    end

    def has_all_roles?(*role_names, resource: nil)
      role_names.flatten.all? { |role_name| has_role?(role_name, resource) }
    end

    def has_any_role_of?(*role_names, resource: nil)
      role_names.flatten.any? { |role_name| has_role?(role_name, resource) }
    end

    def resources(resource_class)
      assignment_table = RoleFu.role_assignment_class.table_name
      query = resource_class.joins(:roles).merge(roles.where(resource_type: resource_class.name))

      if RoleFu.role_assignment_class.column_names.include?("expires_at")
        query = query.where("#{assignment_table}.expires_at IS NULL OR #{assignment_table}.expires_at > ?", Time.current)
      end

      query.distinct
    end

    def method_missing(method_name, *args, &block)
      if (role_name = parse_dynamic_role_name(method_name))
        has_role?(role_name, *args)
      else
        super
      end
    end

    def respond_to_missing?(method_name, include_private = false)
      parse_dynamic_role_name(method_name) || super
    end

    private

    def parse_dynamic_role_name(method_name)
      return nil unless (regex = RoleFu.configuration.dynamic_shortcuts_regex)

      match = method_name.to_s.match(regex)
      match ? match[:role] : nil
    end

    def filter_expired(relation)
      return relation unless RoleFu.role_assignment_class.column_names.include?("expires_at")

      assignment_table = RoleFu.role_assignment_class.table_name
      relation.joins(:role_assignments)
        .where("#{assignment_table}.user_id = ? AND (#{assignment_table}.expires_at IS NULL OR #{assignment_table}.expires_at > ?)", id, Time.current)
        .distinct
    end

    def find_or_create_role(role_name, resource)
      RoleFu.role_class.find_or_create_by(
        name: role_name.to_s,
        resource_type: resource_type_for(resource),
        resource_id: resource_id_for(resource)
      )
    end

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

    def resource_type_for(resource)
      return if resource.nil?

      resource.is_a?(Class) ? resource.to_s : resource.class.name
    end

    def resource_id_for(resource)
      return if resource.nil? || resource.is_a?(Class)

      resource.id
    end

    def run_role_fu_callback(callback_name, role)
      method_name = role_fu_callbacks[callback_name]
      return unless method_name

      if respond_to?(method_name, true) || method_name.is_a?(Proc)
        method_name.is_a?(Proc) ? instance_exec(role, &method_name) : send(method_name, role)
      end
    end
  end
end
