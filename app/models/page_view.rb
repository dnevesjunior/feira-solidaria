# frozen_string_literal: true

# Contagem diária de visitas por caminho (ADR 0008). Nenhum dado por
# requisição: sem IP, sem user-agent, sem cookie, sem query string.
class PageView < ApplicationRecord
  BOT_PATTERN = /bot|crawl|spider|slurp|preview|fetch|monitor|curl|wget|python|http/i

  def self.count!(path, day: Date.current)
    upsert(
      { path: path, day: day, count: 1 },
      unique_by: %i[path day],
      on_duplicate: Arel.sql("count = page_views.count + 1")
    )
  end

  # O user-agent é lido só para descartar bots óbvios; não é armazenado.
  def self.bot?(user_agent) = user_agent.blank? || user_agent.match?(BOT_PATTERN)
end
