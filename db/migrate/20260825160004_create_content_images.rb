# Imagens usadas no conteúdo da vitrine. Escopadas por empreendimento (ADR 0005):
# uma imagem de A nunca renderiza na página de B.
class CreateContentImages < ActiveRecord::Migration[8.1]
  def change
    create_table :content_images do |t|
      t.references :enterprise, null: false, foreign_key: true
      t.integer :width
      t.integer :height

      t.timestamps
    end
  end
end
