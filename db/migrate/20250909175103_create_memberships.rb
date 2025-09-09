class CreateMemberships < ActiveRecord::Migration[8.0]
  def change
    create_table :memberships do |t|
      t.references :user, null: false, foreign_key: true
      t.references :team, null: false, foreign_key: true
      t.integer :role, null: false, default: 2  # member

      t.timestamps
    end
    
    add_index :memberships, [:user_id, :team_id], unique: true
    add_index :memberships, [:team_id, :role]
  end
end
