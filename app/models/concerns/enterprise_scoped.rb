# frozen_string_literal: true

# Escopo por empreendimento (ADR 0005, CLAUDE.md §3.5).
#
# Todo modelo com coluna enterprise_id inclui este concern — o teste
# spec/schema/enterprise_scope_spec.rb garante. Sem default_scope: o escopo é
# explícito em cada leitura, e as leituras que cruzam empreendimentos (hub,
# catálogo agregado) são query objects nomeados, não um `unscoped` escondido.
module EnterpriseScoped
  extend ActiveSupport::Concern

  class MissingScope < StandardError; end

  included do
    belongs_to :enterprise
    scope :of, ->(enterprise) { where(enterprise:) }
  end

  class_methods do
    # Falha alto se não houver empreendimento no contexto: melhor um erro do
    # que devolver dado de todas as lojas.
    def for_current
      enterprise = Current.enterprise
      raise MissingScope, "#{name}.for_current sem Current.enterprise" if enterprise.nil?
      of(enterprise)
    end
  end
end
