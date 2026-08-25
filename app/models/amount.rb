# frozen_string_literal: true

# Valor monetário: inteiro na menor unidade + unidade explícita (ADR 0004,
# CLAUDE.md §3.1).
#
# Real (:brl) e Chiquinho (:chiquinho) são unidades distintas e não somáveis.
# Somar, subtrair ou comparar valores de unidades diferentes levanta
# Amount::UnitMismatch. Não existe conversão aqui, de propósito: a troca entre
# Real e Chiquinho, quando existir (Epic 6), é um lançamento explícito com
# regra vinda de governança (Epic 5) — nunca aritmética escondida num tipo.
#
# Nunca aceita Float. Nunca divide por 100.0. A formatação é feita com
# aritmética inteira.
class Amount
  include Comparable

  UNITS = %i[brl chiquinho].freeze

  class UnitMismatch < StandardError; end

  attr_reader :value, :unit

  def self.brl(value) = new(value, :brl)
  def self.chiquinho(value) = new(value, :chiquinho)

  def self.zero(unit) = new(0, unit)

  def initialize(value, unit)
    unless value.is_a?(Integer)
      raise ArgumentError, "valor monetário precisa ser Integer na menor unidade; recebido #{value.class}"
    end
    unit = unit.to_sym if unit.is_a?(String)
    raise ArgumentError, "unidade desconhecida: #{unit.inspect} (esperado uma de #{UNITS.inspect})" unless UNITS.include?(unit)

    @value = value
    @unit = unit
    freeze
  end

  def +(other) = with_same_unit(other) { |o| self.class.new(value + o.value, unit) }
  def -(other) = with_same_unit(other) { |o| self.class.new(value - o.value, unit) }
  def -@ = self.class.new(-value, unit)

  def *(factor)
    raise ArgumentError, "multiplicador precisa ser Integer; recebido #{factor.class}" unless factor.is_a?(Integer)
    self.class.new(value * factor, unit)
  end

  def <=>(other)
    return nil unless other.is_a?(Amount)
    with_same_unit(other) { |o| value <=> o.value }
  end

  # Igualdade nunca levanta: valores de unidades diferentes simplesmente não
  # são iguais.
  def ==(other) = other.is_a?(Amount) && other.unit == unit && other.value == value
  alias eql? ==
  def hash = [ self.class, unit, value ].hash

  def zero? = value.zero?
  def positive? = value.positive?
  def negative? = value.negative?
  def brl? = unit == :brl
  def chiquinho? = unit == :chiquinho

  def to_s
    case unit
    when :brl then format_brl
    when :chiquinho then format_chiquinho
    end
  end

  def inspect = "#<Amount #{self}>"

  private

  def with_same_unit(other)
    raise ArgumentError, "esperado Amount; recebido #{other.class}" unless other.is_a?(Amount)
    unless other.unit == unit
      raise UnitMismatch, "não se soma #{unit} com #{other.unit}: são unidades distintas (CLAUDE.md §3.1)"
    end
    yield other
  end

  def format_brl
    reais, centavos = value.abs.divmod(100)
    inteiro = reais.to_s.reverse.scan(/\d{1,3}/).join(".").reverse
    "#{'-' if value.negative?}R$ #{inteiro},#{format('%02d', centavos)}"
  end

  # Grafia e símbolo do Chiquinho serão confirmados com a feira (Epic 6).
  def format_chiquinho
    inteiro = value.abs.to_s.reverse.scan(/\d{1,3}/).join(".").reverse
    nome = value.abs == 1 ? "Chiquinho" : "Chiquinhos"
    "#{'-' if value.negative?}#{inteiro} #{nome}"
  end
end
