class CreateTeams < ActiveRecord::Migration[8.0]
  def change
    create_table :teams do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.datetime :deleted_at

      t.timestamps
    end
    add_index :teams, :slug, unique: true
    add_index :teams, :deleted_at
  end
end
