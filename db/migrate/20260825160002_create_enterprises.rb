# Empreendimento: unidade familiar ou coletiva membro da rede (CLAUDE.md §4).
# É a raiz do escopo (ADR 0005) — não tem enterprise_id.
class CreateEnterprises < ActiveRecord::Migration[8.1]
  def change
    create_table :enterprises do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.string :short_description
      # Território em granularidade grossa (bairro), nunca endereço (Epic 1.1).
      t.string :neighborhood
      t.string :whatsapp, null: false
      t.string :instagram
      # Documento EditorJS, validado por allowlist (ADR 0009). Nunca HTML.
      t.jsonb :content, null: false, default: { blocks: [] }
      t.string :status, null: false, default: "draft"
      t.timestamptz :published_at

      t.timestamps
    end
    add_index :enterprises, :slug, unique: true
    add_index :enterprises, :status
  end
end
