# Catálogo da feira (Epic 2.4): produtos de toda a rede, em ordem rotativa.
# Cada item leva à vitrine do empreendimento — a loja é a unidade de
# apresentação, não o produto solto.
class CatalogController < ApplicationController
  allow_unauthenticated_access

  def index
    @search = params[:q].to_s.strip.first(60)
    @categories = Category.ordered
    @category = @categories.find_by(slug: params[:categoria]) if params[:categoria].present?
    @products = PublishedProductsQuery.call(search: @search, category: @category)
    @ordering_seed = HubOrdering::DailyRotation.seed
  end
end
