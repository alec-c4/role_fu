# frozen_string_literal: true

module RoleFu
  class Cleanup
    def self.call
      assignment_class = RoleFu.configuration.role_assignment_class_name.constantize

      if assignment_class.column_names.include?("expires_at")
        count = assignment_class.where("expires_at < ?", Time.current).delete_all
        {deleted: count}
      else
        {deleted: 0, error: "expires_at column missing"}
      end
    end
  end
end
