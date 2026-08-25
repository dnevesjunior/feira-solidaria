# frozen_string_literal: true

# Registro próprio de erros (ADR 0008). Sem serviço externo. Mensagem e
# backtrace passam por scrub antes de gravar; retenção de 90 dias.
class ErrorReport < ApplicationRecord
  RETENTION = 90.days

  def self.purge_expired! = where(occurred_at: ...RETENTION.ago).delete_all
end
