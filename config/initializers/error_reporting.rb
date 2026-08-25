# Erros vão para tabela própria, não para terceiros (ADR 0008, CLAUDE.md §3.3).
Rails.application.config.to_prepare do
  Rails.error.unsubscribe(ErrorReport::Subscriber)
  Rails.error.subscribe(ErrorReport::Subscriber.new)
end
