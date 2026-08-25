# Página inicial da feira: quem é a rede, próxima feira, e os empreendimentos
# publicados em ordem rotativa (Epic 1.2).
class HubController < ApplicationController
  allow_unauthenticated_access

  def index
    @search = params[:q].to_s.strip.first(60)
    @enterprises = PublishedEnterprisesQuery.call(search: @search)
    @next_fair = FairEvent.next
    @ordering_seed = HubOrdering::DailyRotation.seed
  end
end
