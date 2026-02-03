# frozen_string_literal: true

namespace :role_fu do
  desc "Clean up expired role assignments"
  task cleanup: :environment do
    result = RoleFu::Cleanup.call
    puts result[:error] || "Deleted #{result[:deleted]} expired role assignment(s)."
  end
end
