# Sessões persistidas, sem ip_address nem user_agent (minimização — CLAUDE.md §3.3).
class CreateSessions < ActiveRecord::Migration[8.1]
  def change
    create_table :sessions do |t|
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
