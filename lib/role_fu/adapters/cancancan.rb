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
            begin
              subject_class = subject_name.classify.constantize
              can rule.to_sym, subject_class
            rescue NameError
              can rule.to_sym, subject_name.to_sym
            end
          else
            can action.to_sym, :all
          end
        end
      end
    end
  end
end
