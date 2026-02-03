# frozen_string_literal: true

module RoleFu
  module Adapters
    module Pundit
      # Mixin for Pundit Policies (e.g. ApplicationPolicy)
      def method_missing(method, *args, &block)
        if method.to_s.end_with?("?")
          action = method.to_s.delete_suffix("?")

          # Infer resource from policy name: PostPolicy -> "posts"
          resource_name = self.class.to_s.gsub("Policy", "").underscore.pluralize

          # Check "posts.update"
          permission = "#{resource_name}.#{action}"

          return true if user.role_fu_can?(permission)
        end

        super
      end

      def respond_to_missing?(method, include_private = false)
        method.to_s.end_with?("?") || super
      end
    end
  end
end
