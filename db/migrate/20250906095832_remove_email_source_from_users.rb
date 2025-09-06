class RemoveEmailSourceFromUsers < ActiveRecord::Migration[8.0]
  def up
    # First, ensure all users have email addresses (migrate manual users if needed)
    User.where(email: nil).find_each do |user|
      # Set a placeholder email for users without one
      # In production, you might want to handle this differently
      user.update!(email: "user-#{user.id}@example.com")
    end

    # Remove the email_source column
    remove_column :users, :email_source, :string

    # Add NOT NULL constraint to email
    change_column_null :users, :email, false
  end

  def down
    # Add back the email_source column
    add_column :users, :email_source, :string, default: "auth_provider"

    # Remove NOT NULL constraint from email
    change_column_null :users, :email, true

    # Update email_source for all users (assume all existing emails are from auth providers)
    User.update_all(email_source: "auth_provider")
  end
end
