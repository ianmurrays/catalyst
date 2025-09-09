class CreateInvitations < ActiveRecord::Migration[8.0]
  def change
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
  end
end
