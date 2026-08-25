# Quem participa de mais de um empreendimento escolhe qual está editando.
class MyEnterprise::ChoicesController < MyEnterprise::BaseController
  def index
    @enterprises = Current.user.enterprises.order(:name)
  end

  def create
    chosen = Current.user.enterprises.find(params[:enterprise_id])
    session[:enterprise_id] = chosen.id
    redirect_to my_enterprise_path
  end
end
