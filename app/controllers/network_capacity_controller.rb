# Capacidade produtiva da rede (Epic 2.5): visível a todos os membros
# (revisão 2.5). Só leitura.
class NetworkCapacityController < ApplicationController
  def index
    @categories = Category.ordered
    @category = @categories.find_by(slug: params[:categoria]) if params[:categoria].present?
    @rows = NetworkCapacityQuery.call(category: @category)
    @total = NetworkCapacityQuery.total(@rows)
  end
end
