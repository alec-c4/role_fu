# frozen_string_literal: true

require_relative "lib/role_fu/version"

Gem::Specification.new do |spec|
  spec.name = "role_fu"
  spec.version = RoleFu::VERSION
  spec.authors = ["Alexey Poimtsev"]
  spec.email = ["alexey.poimtsev@gmail.com"]

  spec.summary = "A modern role management gem for Rails, replacing rolify."
  spec.description = "RoleFu provides explicit role management with Role and RoleAssignment models, avoiding hidden HABTM tables. Supports scopes, resource-specific roles, and cleaner architecture."
  spec.homepage = "https://github.com/alec-c4/role_fu"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/alec-c4/role_fu"
  spec.metadata["changelog_uri"] = "https://github.com/alec-c4/role_fu/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ Gemfile .gitignore .rspec spec/ .github/ .rubocop.yml])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "activerecord", ">= 7.2"

  spec.add_development_dependency "appraisal"
  spec.add_development_dependency "lefthook"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "simplecov", "~> 0.21"
  spec.add_development_dependency "sqlite3", "~> 2.0"
end
