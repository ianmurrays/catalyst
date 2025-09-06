class AddEmailSourceToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :email_source, :string, default: 'manual'
    add_index :users, :email_source
  end
end
