# frozen_string_literal: true

# Leitura que cruza empreendimentos, nomeada de propósito (ADR 0005): o hub.
# Ordem vem da regra de governança; busca é por nome, sem relevância.
class PublishedEnterprisesQuery < ApplicationQuery
  def initialize(search: nil, date: Date.current)
    @search = search.to_s.strip.presence
    @date = date
  end

  def call
    scope = Enterprise.published.with_attached_profile_image
    scope = scope.where("unaccent(enterprises.name) ILIKE unaccent(?)", "%#{sanitize(@search)}%") if @search
    HubOrdering.for.apply(scope, date: @date)
  end

  private

  def sanitize(term) = ActiveRecord::Base.sanitize_sql_like(term)
end
