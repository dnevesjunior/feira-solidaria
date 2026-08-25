# frozen_string_literal: true

# Tipo ActiveModel para persistir Amount numa coluna bigint (ADR 0004).
#
#   attribute :price_cents, :amount, unit: :brl
#
# A unidade é declarada por atributo no código, não armazenada por linha. Uma
# tabela que precise das duas unidades tem duas colunas. Assim a soma acidental
# continua impossível pelo tipo, e um SUM(coluna) nunca mistura unidades.
class Amount::Type < ActiveModel::Type::Value
  attr_reader :unit

  def initialize(unit:)
    super()
    @unit = unit.to_sym
    raise ArgumentError, "unidade desconhecida: #{unit.inspect}" unless Amount::UNITS.include?(@unit)
  end

  def type = :integer

  def cast(raw)
    case raw
    when nil then nil
    when Amount
      raise Amount::UnitMismatch, "atributo é #{unit}, recebido #{raw.unit}" unless raw.unit == unit
      raw
    when Integer then Amount.new(raw, unit)
    when String
      raw.strip.empty? ? nil : Amount.new(Integer(raw.strip, 10), unit)
    else
      raise ArgumentError, "não converte #{raw.class} em Amount (nunca Float — CLAUDE.md §3.1)"
    end
  end

  def serialize(amount) = cast(amount)&.value

  def deserialize(raw) = raw.nil? ? nil : Amount.new(Integer(raw), unit)
end
