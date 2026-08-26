# frozen_string_literal: true

# Capacidade produtiva da rede (Epic 2.5): para cada produto (nome
# normalizado), soma da capacidade semanal declarada e nº de empreendimentos.
# Só leitura; visível a todos os membros (revisão 2.5). É a primeira vez que a
# rede consegue se ver como capacidade coletiva.
class NetworkCapacityQuery < ApplicationQuery
  Row = Data.define(:name, :weekly_total, :enterprises, :category)

  def initialize(category: nil)
    @category = category
  end

  def call
    scope = Product.published.joins(:enterprise).merge(Enterprise.published)
      .where.not(capacity_quantity: nil)
    scope = scope.where(category: @category) if @category

    scope
      .group(Arel.sql("unaccent(lower(products.name))"))
      .pluck(
        Arel.sql("min(products.name)"),
        Arel.sql("sum(#{Product::Capacity::WEEKLY_SQL})"),
        Arel.sql("count(distinct products.enterprise_id)"),
        Arel.sql("min(products.category_id)")
      )
      .map { |name, total, count, category_id| Row.new(name:, weekly_total: total.to_i, enterprises: count, category: category_id) }
      .sort_by { |row| row.name.downcase }
  end

  def self.total(rows) = rows.sum(&:weekly_total)
end
