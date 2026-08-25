# frozen_string_literal: true

# Regra de ordenação do hub, lida do parâmetro de governança (Epic 1.2;
# CLAUDE.md §3.2). Nunca por desempenho, nunca por data de cadastro, nunca por
# ordem alfabética.
module HubOrdering
  def self.for(rule = Governance::Parameter.value_for(:hub_ordering))
    case rule
    when "daily_rotation" then DailyRotation
    else raise ArgumentError, "regra de ordenação desconhecida: #{rule.inspect}"
    end
  end

  # Embaralhamento determinístico com semente diária: todos veem a mesma
  # ordem no mesmo dia, ninguém acumula posição, e a semente é publicável.
  module DailyRotation
    def self.seed(date = Date.current) = date.iso8601

    def self.apply(relation, date: Date.current)
      relation.order(Arel.sql("md5(enterprises.id::text || #{relation.connection.quote(seed(date))})"))
    end
  end
end
