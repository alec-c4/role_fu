# frozen_string_literal: true

module RoleFu
  # Raised by RoleFu::Authorizable guard methods. Rescue it yourself
  # (e.g. `rescue_from RoleFu::AccessDenied` in ApplicationController) —
  # role_fu does not register a rescue handler on your behalf.
  class AccessDenied < RoleFu::Error
    def initialize(message = "You are not authorized to perform this action.")
      super
    end
  end

  # Minimal, framework-agnostic authorization guard for apps that don't want
  # to pull in a full authorization gem just to raise on a missing role.
  #
  # This is deliberately NOT an `allow`/`deny` DSL or a rule-resolution
  # engine — for anything beyond "raise unless this check passes", reach for
  # the Pundit or CanCanCan adapters instead. Mixing this concern into a
  # controller (or any object that responds to `current_user`, or overrides
  # `role_fu_current_user`) just gives you two guard-clause helpers built on
  # top of the `has_role?` / `role_fu_can?` methods you already have.
  module Authorizable
    extend ActiveSupport::Concern

    # Override this if the current user isn't exposed via `current_user`
    # (e.g. in a job or service object).
    def role_fu_current_user
      current_user if respond_to?(:current_user)
    end

    def role_fu_authorize!(role_name, resource = nil)
      user = role_fu_current_user
      raise RoleFu::AccessDenied unless user&.respond_to?(:has_role?) && user.has_role?(role_name, resource)

      true
    end

    def role_fu_can!(action, resource = nil, field: nil)
      user = role_fu_current_user
      raise RoleFu::AccessDenied unless user&.respond_to?(:role_fu_can?) && user.role_fu_can?(action, resource, field: field)

      true
    end
  end
end
