# Expurgo de relatórios de erro após 90 dias (ADR 0008). Agendado em config/recurring.yml.
class PurgeErrorReportsJob < ApplicationJob
  queue_as :default

  def perform
    removed = ErrorReport.purge_expired!
    Rails.logger.info("PurgeErrorReportsJob: #{removed} relatório(s) removido(s)")
  end
end
