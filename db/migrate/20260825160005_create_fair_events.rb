# "Próxima feira": data e local da feira presencial. Dado da rede, não de uma loja.
class CreateFairEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :fair_events do |t|
      t.timestamptz :starts_at, null: false
      t.timestamptz :ends_at
      t.string :place, null: false
      t.text :notes

      t.timestamps
    end
    add_index :fair_events, :starts_at
  end
end
