# frozen_string_literal: true

module RoleFu
  module Permission
    extend ActiveSupport::Concern

    included do
      belongs_to :role, class_name: RoleFu.configuration.role_class_name
      validates :action, presence: true
    end
  end
end
