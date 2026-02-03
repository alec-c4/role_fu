# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

require "rubocop/rake_task"

RuboCop::RakeTask.new

# Mock :environment task since we are not in a Rails app
task :environment do
  # No-op
end

namespace :maintenance do
  desc "Update all appraisal lockfiles"
  task :update_appraisals do
    sh "bundle exec appraisal install"
    sh "bundle exec appraisal bundle update --all"
  end
end

task default: %i[spec rubocop]
