# Log de eventos append-only (ADR 0006, CLAUDE.md §3.3).
#
# A imutabilidade é imposta no banco por trigger: nenhum UPDATE ou DELETE
# passa, venha do ActiveRecord, de uma migration ou de um psql. Por isso o
# schema é dump em SQL (config.active_record.schema_format = :sql).
class CreateEvents < ActiveRecord::Migration[8.1]
  def up
    create_table :events do |t|
      t.string :kind, null: false
      t.references :actor, polymorphic: true
      t.references :subject, polymorphic: true
      t.jsonb :payload, null: false, default: {}
      t.timestamptz :occurred_at, null: false
      t.timestamptz :created_at, null: false, default: -> { "CURRENT_TIMESTAMP" }
    end
    add_index :events, :kind
    add_index :events, :occurred_at

    execute <<~SQL
      CREATE FUNCTION events_append_only() RETURNS trigger AS $$
      BEGIN
        RAISE EXCEPTION 'events é append-only: % não é permitido', TG_OP;
      END;
      $$ LANGUAGE plpgsql;

      CREATE TRIGGER events_append_only
        BEFORE UPDATE OR DELETE ON events
        FOR EACH ROW EXECUTE FUNCTION events_append_only();
    SQL
  end

  def down
    execute "DROP TRIGGER IF EXISTS events_append_only ON events"
    execute "DROP FUNCTION IF EXISTS events_append_only()"
    drop_table :events
  end
end
