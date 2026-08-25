require "rails_helper"

# CLAUDE.md §3.1: valores monetários são inteiros. Estrito de propósito
# (ADR 0004): nenhuma coluna de ponto flutuante ou decimal em lugar nenhum.
RSpec.describe "Schema: nenhum ponto flutuante" do
  FORBIDDEN_SQL_TYPES = %w[float double\ precision real numeric decimal].freeze

  it "não tem coluna float, double precision, real, numeric ou decimal" do
    connection = ActiveRecord::Base.connection
    offenders = connection.tables.flat_map do |table|
      connection.columns(table)
        .select { |c| FORBIDDEN_SQL_TYPES.any? { |t| c.sql_type.start_with?(t) } || %i[float decimal].include?(c.type) }
        .map { |c| "#{table}.#{c.name} (#{c.sql_type})" }
    end
    expect(offenders).to be_empty, "colunas proibidas: #{offenders.join(', ')}"
  end
end
