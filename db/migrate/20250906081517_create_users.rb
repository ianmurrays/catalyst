class CreateUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :users do |t|
      t.string :auth0_sub, null: false
      t.string :display_name
      t.text :bio
      t.string :phone
      t.string :website
      t.string :company
      t.json :preferences
      t.datetime :profile_completed_at
      t.integer :updated_count, default: 0, null: false
      t.datetime :last_update_window

      t.timestamps
    end
    add_index :users, :auth0_sub, unique: true
  end
end
