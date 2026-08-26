# Produto com capacidade declarada (Epic 2). Não há estoque: há quanto a
# família consegue produzir por período, e isso é declaração, não contrato.
class CreateProducts < ActiveRecord::Migration[8.1]
  def change
    create_table :products do |t|
      t.references :enterprise, null: false, foreign_key: true
      t.references :category, foreign_key: true
      t.string :name, null: false
      t.text :description
      # Inteiro em centavos (ADR 0004): attribute :price, :amount, unit: :brl
      t.bigint :price_cents, null: false
      t.string :sale_unit, null: false, default: "unidade"
      t.string :status, null: false, default: "draft"
      t.integer :capacity_quantity
      t.string :capacity_period, null: false, default: "week"
      t.integer :lead_time_days

      t.timestamps
    end
    add_index :products, [ :enterprise_id, :status ]
    add_index :products, [ :enterprise_id, :name ]
  end
end
