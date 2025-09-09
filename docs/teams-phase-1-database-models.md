# Phase 1: Database Schema & Models

## Objective
Create the database schema and ActiveRecord models for teams, memberships, and invitations with proper associations, validations, and business logic.

## Dependencies
- Existing User model
- Audited gem (for tracking changes)

## Database Schema

### Teams Table
```ruby
create_table :teams do |t|
  t.string :name, null: false
  t.string :slug, null: false
  t.datetime :deleted_at  # for soft deletion
  t.timestamps
end

add_index :teams, :slug, unique: true
add_index :teams, :deleted_at
```

### Memberships Table
```ruby
create_table :memberships do |t|
  t.references :user, null: false, foreign_key: true
  t.references :team, null: false, foreign_key: true
  t.integer :role, null: false, default: 2  # member
  t.timestamps
end

add_index :memberships, [:user_id, :team_id], unique: true
add_index :memberships, [:team_id, :role]
```

### Invitations Table
```ruby
create_table :invitations do |t|
  t.references :team, null: false, foreign_key: true
  t.string :token, null: false
  t.integer :role, null: false, default: 2  # member
  t.datetime :expires_at
  t.references :created_by, null: false, foreign_key: { to_table: :users }
  t.datetime :used_at
  t.references :used_by, foreign_key: { to_table: :users }
  t.timestamps
end

add_index :invitations, :token, unique: true
add_index :invitations, [:team_id, :expires_at]
```

## Models Implementation

### Team Model
Key features:
- Slug generation from name
- Soft deletion with `deleted_at`
- Audit trail with audited gem
- Has many memberships and users through memberships
- Has many invitations
- Validation for name presence and uniqueness (scoped to non-deleted)
- Method to check if user is member/owner/admin

### Membership Model
Key features:
- Belongs to user and team
- Role enum: { owner: 0, admin: 1, member: 2, viewer: 3 }
- Validation for unique user per team
- Audit trail for role changes
- Scope for active memberships (non-deleted teams)

### Invitation Model
Key features:
- Belongs to team and created_by user
- Secure token generation (use SecureRandom.urlsafe_base64)
- Expiration options: { "1 hour", "1 day", "3 days", "1 week", "never" }
- Method to check if expired
- Method to accept invitation (creates membership)
- Scope for active invitations (not used, not expired)

## Testing Requirements

### Model Specs
1. Team model specs:
   - Validations (name presence, slug uniqueness)
   - Associations
   - Slug generation
   - Soft deletion behavior
   - Member checking methods

2. Membership model specs:
   - Validations (unique user per team)
   - Role enum behavior
   - Associations
   - Scopes

3. Invitation model specs:
   - Token generation uniqueness
   - Expiration logic
   - Acceptance flow
   - Associations
   - Validation of role values

### Factory Definitions
Create factories for all three models with traits:
- Team: with_members, deleted
- Membership: owner, admin, member, viewer
- Invitation: expired, used

## Implementation Steps (TDD)

1. Generate migrations:
   ```bash
   rails g migration CreateTeams name:string slug:string:uniq deleted_at:datetime
   rails g migration CreateMemberships user:references team:references role:integer
   rails g migration CreateInvitations
   ```

2. Write failing model specs first
3. Create models with minimum code to pass specs
4. Add associations and validations
5. Implement business logic methods
6. Add scopes and callbacks
7. Run all specs and ensure green

## Key Considerations

1. **Slug Generation**: Use a concern or before_validation callback to generate URL-friendly slugs
2. **Soft Deletion**: Consider using a concern for soft-delete behavior
3. **Role Constants**: Define role constants for easier reference in policies
4. **Token Security**: Ensure invitation tokens are cryptographically secure
5. **Database Indexes**: Add appropriate indexes for performance
6. **Auditing**: Configure audited gem for important fields
7. **Cascading**: Handle cascading deletes appropriately
8. **Validation Messages**: Use i18n for all validation error messages

## Integration Points

- User model needs `has_many :memberships` and `has_many :teams, through: :memberships`
- Consider adding convenience methods to User like `owned_teams`, `admin_teams`
- Audit trail should capture who made changes to teams/memberships