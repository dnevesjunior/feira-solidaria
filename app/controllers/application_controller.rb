class ApplicationController < ActionController::Base
  include Authentication

  # Sem allow_browser: o público usa Android de baixo custo com navegador
  # antigo (CLAUDE.md §3.6). Bloquear navegador é bloquear família.

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  after_action :count_page_view

  private

  # Telemetria própria (ADR 0008): só o caminho e o dia. Nunca derruba a
  # requisição.
  def count_page_view
    return unless request.get? && response.status == 200 && response.media_type == "text/html"
    return if PageView.bot?(request.user_agent)
    PageView.count!(request.path)
  rescue StandardError => e
    Rails.error.report(e, handled: true, severity: :warning)
  end
end
