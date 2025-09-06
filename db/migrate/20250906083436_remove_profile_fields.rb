class RemoveProfileFields < ActiveRecord::Migration[8.0]
  def change
    remove_column :users, :website, :string
    remove_column :users, :company, :string
    remove_column :users, :profile_completed_at, :datetime
    remove_column :users, :updated_count, :integer
    remove_column :users, :last_update_window, :datetime
  end
end
