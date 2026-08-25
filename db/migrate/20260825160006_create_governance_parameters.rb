# Parâmetros de governança vivem em banco, com default declarado no código,
# nunca como constante (CLAUDE.md §3.4; ADR 0011). O Epic 5 acrescenta autor,
# valor anterior, justificativa e o processo de assembleia.
class CreateGovernanceParameters < ActiveRecord::Migration[8.1]
  def change
    create_table :governance_parameters do |t|
      t.string :key, null: false
      t.jsonb :value, null: false
      t.text :note
      t.timestamptz :created_at, null: false, default: -> { "CURRENT_TIMESTAMP" }
    end
    add_index :governance_parameters, [ :key, :created_at ]
  end
end
