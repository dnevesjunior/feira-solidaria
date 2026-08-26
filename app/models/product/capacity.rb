# frozen_string_literal: true

# Capacidade declarada (Epic 2.2; ADR 0013): "quanto você consegue fazer, mais
# ou menos" por período. Normalização para semana com aritmética inteira —
# é aproximado por definição, e o número deve ser lido assim.
module Product::Capacity
  PERIODS = %w[day week month].freeze
  PERIOD_LABELS = { "day" => "por dia", "week" => "por semana", "month" => "por mês" }.freeze

  # SQL equivalente a .weekly, para agregação no banco.
  WEEKLY_SQL = <<~SQL.squish
    CASE products.capacity_period
      WHEN 'day' THEN products.capacity_quantity * 7
      WHEN 'week' THEN products.capacity_quantity
      WHEN 'month' THEN products.capacity_quantity * 12 / 52
    END
  SQL

  def self.weekly(quantity, period)
    return nil if quantity.nil?
    case period
    when "day" then quantity * 7
    when "week" then quantity
    when "month" then quantity * 12 / 52
    else raise ArgumentError, "período desconhecido: #{period.inspect}"
    end
  end

  def self.label(period) = PERIOD_LABELS.fetch(period)
end
