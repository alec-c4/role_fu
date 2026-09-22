# frozen_string_literal: true

module RoleFu
  module Adapters
    module CanCanCan
      # Mixin for CanCan::Ability class
      def role_fu_load_permissions!(user)
        return unless user.respond_to?(:role_fu_permissions)

        user.role_fu_permissions.each do |action|
          # Action format: "posts.update" (resource.action) or "manage_all"
          parts = action.split(".")

          if parts.size == 2
            subject_name, rule = parts
            subject_class = begin
              subject_name.classify.constantize
            rescue NameError
              subject_name.to_sym
            end

            # Field-scoped permissions map onto CanCanCan's own attribute
            # restriction (`can :update, Post, :title`) instead of role_fu
            # re-implementing attribute authorization itself.
            fields = user.role_fu_permitted_fields(action)
            if fields == :all
              can rule.to_sym, subject_class
            else
              can rule.to_sym, subject_class, *fields.map(&:to_sym)
            end
          else
            can action.to_sym, :all
          end
        end
      end
    end
  end
end
