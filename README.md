# RoleFu

RoleFu is a modern, explicit role management gem for Ruby on Rails. It is designed as a cleaner, more performant alternative to `rolify`.

## Why RoleFu?

- **Explicit Models**: Unlike Rolify which often uses hidden `has_and_belongs_to_many` tables, RoleFu uses an explicit `RoleAssignment` join model. This makes it easier to extend with metadata (e.g., `created_by`, `expires_at`).
- **N+1 Prevention**: Built-in support for `has_cached_role?` to work with preloaded associations.
- **Strict by Default**: Focused on resource-specific roles with clear `has_role?` semantics.
- **Orphaned Role Cleanup**: Automatically deletes roles when the last user assignment is removed.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'role_fu'
```

And then execute:

```bash
bundle install
```

### Setup

1. Run the install generator to create the configuration:
```bash
rails generate role_fu:install
```

2. Generate the Role models (default names are `Role` and `RoleAssignment`):
```bash
rails generate role_fu Role User
```

3. Run migrations:
```bash
rails db:migrate
```

## Usage

### Roleable (User Model)

Include `RoleFu::Roleable` in your User model (done automatically by the generator).

```ruby
class User < ApplicationRecord
  include RoleFu::Roleable
  
  # Optional callbacks
  role_fu_options after_add: :notify_user
  
  def notify_user(role)
    # ...
  end
end
```

#### Basic Operations

```ruby
user = User.find(1)

# Global roles
user.add_role(:admin)
user.has_role?(:admin) # => true
user.remove_role(:admin)

# Resource-specific roles
org = Organization.first
user.add_role(:manager, org)
user.has_role?(:manager, org) # => true
user.has_role?(:manager)      # => false (strict check)
user.has_role?(:manager, :any) # => true
```

#### Performance (N+1 Prevention)

Use `has_cached_role?` when roles are preloaded.

```ruby
users = User.includes(:roles).all
users.each do |user|
  user.has_cached_role?(:admin) # No extra queries!
end
```

### Resourceable (Models with roles)

Include `RoleFu::Resourceable` in any model that should have roles scoped to it.

```ruby
class Organization < ApplicationRecord
  include RoleFu::Resourceable
end

org = Organization.first
org.users_with_role(:manager)
org.count_users_with_role(:admin)
org.available_roles # ["manager", "admin"]
```

## Comparison with Rolify

| Feature | Rolify | RoleFu |
|---------|--------|--------|
| Join Model | Implicit (HABTM) | Explicit (RoleAssignment) |
| Performance | Frequent N+1 | Cached role support |
| Orphaned Roles | Configurable cleanup | Automatic cleanup |
| Modern Rails | Older codebase | Optimized for Rails 7+ |

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).