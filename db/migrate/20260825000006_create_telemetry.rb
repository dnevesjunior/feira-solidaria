# Telemetria própria (ADR 0008): agregado diário de pageviews sem nenhum dado
# por requisição, e relatório de erros com scrub, retido por 90 dias.
class CreateTelemetry < ActiveRecord::Migration[8.1]
  def change
    create_table :page_views do |t|
      t.string :path, null: false
      t.date :day, null: false
      t.integer :count, null: false, default: 0
    end
    add_index :page_views, [ :path, :day ], unique: true

    create_table :error_reports do |t|
      t.string :exception_class, null: false
      t.text :message
      t.text :backtrace
      t.string :controller
      t.string :action
      t.string :severity
      t.boolean :handled, null: false, default: false
      t.timestamptz :occurred_at, null: false
    end
    add_index :error_reports, :occurred_at
  end
end
