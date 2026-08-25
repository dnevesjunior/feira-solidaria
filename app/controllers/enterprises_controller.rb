# Vitrine pública (Epic 1.3). Só empreendimentos publicados; endereço
# inexistente leva de volta ao hub com a busca aberta.
class EnterprisesController < ApplicationController
  allow_unauthenticated_access

  def show
    @enterprise = Enterprise.published.find_by(slug: params[:slug])
    return render_not_found unless @enterprise
    @document = @enterprise.document
    @html = EditorJs::Renderer.new(@document).to_html
  end

  private

  def render_not_found
    @missing_slug = params[:slug]
    @search = @missing_slug.tr("-", " ")
    @enterprises = PublishedEnterprisesQuery.call(search: @search)
    @next_fair = nil
    @ordering_seed = HubOrdering::DailyRotation.seed
    render "errors/not_found", status: :not_found
  end
end
