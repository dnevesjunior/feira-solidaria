require "rails_helper"

# CLAUDE.md §3.5 / ADR 0005: todo modelo com enterprise_id é escopado pelo
# concern. Verde por vacuidade no Epic 0; obriga o Epic 1 a seguir o padrão.
RSpec.describe "Schema: escopo por empreendimento" do
  before { Rails.application.eager_load! }

  it "todo modelo com coluna enterprise_id inclui EnterpriseScoped" do
    scoped_tables = ActiveRecord::Base.connection.tables.select do |table|
      ActiveRecord::Base.connection.column_exists?(table, :enterprise_id)
    end

    unscoped_models = ApplicationRecord.descendants
      .reject(&:abstract_class?)
      .select { |model| scoped_tables.include?(model.table_name) }
      .reject { |model| model.include?(EnterpriseScoped) }

    expect(unscoped_models).to be_empty,
      "modelos com enterprise_id sem EnterpriseScoped: #{unscoped_models.map(&:name).join(', ')}"
  end

  it "for_current falha alto sem empreendimento no contexto" do
    model = Class.new(ApplicationRecord) do
      self.table_name = "users" # só para o concern carregar
      include EnterpriseScoped
    end
    Current.enterprise = nil
    expect { model.for_current }.to raise_error(EnterpriseScoped::MissingScope)
  end
end
