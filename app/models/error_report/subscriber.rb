# frozen_string_literal: true

# Assinante de Rails.error (ADR 0008). Grava ErrorReport com scrub de dado
# pessoal. Nunca levanta: telemetria não derruba requisição.
class ErrorReport::Subscriber
  PII_PATTERNS = [
    /\+?\d[\d\s().-]{7,}\d/,            # sequências que parecem telefone
    /[\w.+-]+@[\w-]+(?:\.[\w-]+)+/      # e-mails
  ].freeze
  REDACTED = "[removido]"

  def report(error, handled:, severity:, context:, source: nil)
    controller = context[:controller]
    ErrorReport.create!(
      exception_class: error.class.name,
      message: scrub(error.message.to_s).truncate(2000),
      backtrace: scrub(Array(error.backtrace).first(15).join("\n")),
      controller: controller.respond_to?(:controller_name) ? controller.controller_name : controller&.to_s,
      action: context[:action] || (controller.respond_to?(:action_name) ? controller.action_name : nil),
      severity: severity.to_s,
      handled: handled,
      occurred_at: Time.current
    )
  rescue StandardError => e
    Rails.logger.error("ErrorReport::Subscriber falhou: #{e.class}: #{e.message}")
  end

  def scrub(text)
    PII_PATTERNS.reduce(text.to_s) { |acc, pattern| acc.gsub(pattern, REDACTED) }
  end
end
