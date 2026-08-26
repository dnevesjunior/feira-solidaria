# Categorias: lista curta e fechada, definida COM a feira (Epic 2.3). Nasce
# vazia; entra por seed quando existir. Atributo de organização, nunca de
# priorização.
class CreateCategories < ActiveRecord::Migration[8.1]
  def change
    create_table :categories do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.integer :position, null: false, default: 0

      t.timestamps
    end
    add_index :categories, :slug, unique: true
  end
end
