# Pedido roteado ao empreendimento (Epic 3). Nenhum dinheiro passa por aqui.
# Só nome e WhatsApp do comprador (minimização), com expurgo (ADR 0016).
class CreateOrders < ActiveRecord::Migration[8.1]
  def change
    create_table :orders do |t|
      t.references :enterprise, null: false, foreign_key: true
      t.string :token, null: false
      t.string :status, null: false, default: "received"
      t.string :buyer_name
      t.string :buyer_phone
      t.text :buyer_note
      # Congelado na criação (ADR 0004): attribute :total_cents, :amount, unit: :brl
      t.bigint :total_cents, null: false
      t.timestamptz :routed_at
      t.timestamptz :confirmed_at
      t.timestamptz :closed_at
      t.string :outcome
      t.text :outcome_note
      t.timestamptz :buyer_purged_at

      t.timestamps
    end
    add_index :orders, :token, unique: true
    add_index :orders, [ :enterprise_id, :status ]
    add_index :orders, :closed_at

    create_table :order_items do |t|
      t.references :order, null: false, foreign_key: true
      t.references :product, foreign_key: { on_delete: :nullify }
      # Congelados no momento do pedido — o produto muda, o pedido não.
      t.string :product_name, null: false
      t.string :sale_unit, null: false
      t.bigint :unit_price_cents, null: false
      t.integer :quantity, null: false

      t.timestamps
    end
  end
end
