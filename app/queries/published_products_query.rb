# frozen_string_literal: true

# Catálogo da feira (Epic 2.4): produtos publicados de empreendimentos
# publicados, na mesma ordem rotativa do hub. Sem "mais vendidos", sem
# "em alta", sem nada derivado de comportamento ou perfil (CLAUDE.md §3.2).
class PublishedProductsQuery < ApplicationQuery
  def initialize(search: nil, category: nil, date: Date.current)
    @search = search.to_s.strip.presence
    @category = category
    @date = date
  end

  def call
    scope = Product.published.joins(:enterprise).merge(Enterprise.published)
      .includes(:enterprise, :category).with_attached_photos
    scope = scope.where("unaccent(products.name) ILIKE unaccent(?)", "%#{ActiveRecord::Base.sanitize_sql_like(@search)}%") if @search
    scope = scope.where(category: @category) if @category
    scope.order(Arel.sql("md5(products.id::text || #{scope.connection.quote(HubOrdering::DailyRotation.seed(@date))})"))
  end
end
