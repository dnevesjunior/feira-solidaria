class Current < ActiveSupport::CurrentAttributes
  attribute :session
  # Empreendimento da requisição (ADR 0005). Preenchido a partir da associação
  # membro ↔ empreendimento no Epic 1; nulo fora de contexto de loja.
  attribute :enterprise

  delegate :user, to: :session, allow_nil: true
end
