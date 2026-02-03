# RoleFu

RoleFu is a modern, explicit role management gem for Ruby on Rails. It is designed as a cleaner, more performant alternative to legacy role gems, providing full control over role assignments and granular permissions.

## Why RoleFu?

- **Explicit Models**: Uses an explicit `RoleAssignment` join model instead of hidden tables, making it easy to add metadata or audit trails.
- **N+1 Prevention**: Built-in support for `has_cached_role?` and optimized scopes.
- **Strict by Default**: Resource-specific checks are strict, ensuring global roles don't accidentally leak permissions unless configured otherwise.
- **Advanced Features**: Supports temporal (expiring) roles, metadata, audit logging, and granular abilities.
- **Modern Infrastructure**: Fully compatible with Rails 7.0 through 8.1, includes Lefthook and Appraisal support.

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

1. **Install Configuration:**
```bash
rails generate role_fu:install
```

2. **Generate Models:**
Default names are `Role` and `RoleAssignment`, linked to the `User` model.
```bash
rails generate role_fu Role User
```

3. **Run Migrations:**
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
user.grant(:admin)
user.has_role?(:admin) # => true
user.revoke(:admin)

# Resource-specific roles
org = Organization.first
user.grant(:manager, org)
user.has_role?(:manager, org) # => true
user.has_role?(:manager)      # => false (strict check)
user.has_role?(:manager, :any) # => true
user.only_has_role?(:manager, org) # => true if this is their only role
```

#### Scopes (Finders)

```ruby
User.with_role(:admin)
User.with_role(:manager, org)
User.without_role(:admin)
User.with_any_role(:admin, :editor)
User.with_all_roles(:admin, :manager)
```

---

### Advanced Features

#### 1. Temporal Roles (Expiration)
Roles can be assigned with an expiration time. They are automatically filtered out from queries once expired.

```ruby
user.grant(:manager, org, expires_at: 1.week.from_now)

# To physically remove expired roles from the database:
# rake role_fu:cleanup

# Or generate a scheduled ActiveJob:
# rails generate role_fu:job
```

#### 2. Metadata
Attach arbitrary metadata to a role assignment.

```ruby
user.grant(:manager, org, meta: { assigned_by: current_user.id, reason: "Project lead" })
```

#### 3. Audit Log
Track every grant, revoke, and update (e.g., expiration extensions).

**Setup:**
```bash
rails generate role_fu:audit
rails db:migrate
```

**Usage:**
Wrap changes in `with_actor` to capture the responsible user:
```ruby
RoleFu.with_actor(current_user) do
  user.grant(:manager, org)
end

# Check history
RoleAssignmentAudit.where(user: user).last
# => #<RoleAssignmentAudit operation: "INSERT", whodunnit: "1", ...>
```

#### 4. Role Abilities (Permissions)
Attach granular permissions to roles.

**Setup:**
```bash
rails generate role_fu:abilities
rails db:migrate
```

**Usage:**
```ruby
# Setup permissions
manager_role = Role.find_by(name: "manager")
manager_role.permissions.create(action: "posts.edit")

# Check abilities
user.role_fu_can?("posts.edit") # => true
```

---

### Adapters (Pundit & CanCanCan)

#### CanCanCan
```ruby
class Ability
  include CanCan::Ability
  include RoleFu::Adapters::CanCanCan

  def initialize(user)
    role_fu_load_permissions!(user)
  end
end
```

#### Pundit
```ruby
class ApplicationPolicy
  include RoleFu::Adapters::Pundit
end
```
*`PostPolicy#update?` will automatically check `user.role_fu_can?('posts.update')`.*

---

### Performance (N+1 Prevention)

Use `has_cached_role?` when roles are preloaded to avoid database roundtrips.

```ruby
users = User.includes(:roles).all
users.each do |user|
  user.has_cached_role?(:admin) # No extra queries!
end
```

### Resourceable

Include `RoleFu::Resourceable` in any model that should have roles scoped to it.

```ruby
class Organization < ApplicationRecord
  include RoleFu::Resourceable
end

org = Organization.first
org.users_with_role(:manager)
org.available_roles # ["manager", "admin"]

# Scopes
Organization.with_role(:manager, user)
Organization.without_role(:manager, user)
```

## Configuration

Customize your model names in `config/initializers/role_fu.rb`:

```ruby
RoleFu.configure do |config|
  config.user_class_name = "Account"
  config.role_class_name = "Group"
  
  # Enable Rolify-style permissive checks (Global roles override resource checks)
  config.global_roles_override = true
end
```

## Custom Aliases (e.g. Groups)

If you prefer different terminology (e.g., "Groups" instead of "Roles"), you can alias the methods in your models:

```ruby
class User < ApplicationRecord
  include RoleFu::Roleable
  role_fu_alias :group
end

# Now you can use:
user.add_group(:admin)
user.has_group?(:admin)
User.in_group(:admin)      # Alias for with_group/with_role
User.not_in_group(:admin)  # Alias for without_group/without_role
```

## Migrating from Rolify

1. **Code Changes**: Replace `rolify` with `include RoleFu::Roleable` and `resourcify` with `include RoleFu::Resourceable`.
2. **Data Migration**:
```sql
INSERT INTO role_assignments (user_id, role_id, created_at, updated_at)
SELECT user_id, role_id, NOW(), NOW()
FROM users_roles;
```
3. **Behavior**: Set `config.global_roles_override = true` if you rely on global roles satisfying resource checks.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
