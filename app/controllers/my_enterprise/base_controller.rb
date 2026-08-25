# Tudo em /minha-loja passa por aqui. Current.enterprise vem da sessão,
# validado contra as memberships da pessoa — nunca de params (ADR 0005).
class MyEnterprise::BaseController < ApplicationController
  before_action :set_current_enterprise

  private

  def set_current_enterprise
    enterprises = Current.user.enterprises.order(:id)
    Current.enterprise =
      if session[:enterprise_id]
        enterprises.find_by(id: session[:enterprise_id])
      elsif enterprises.one?
        enterprises.first
      end
    return if Current.enterprise

    session.delete(:enterprise_id)
    if enterprises.none?
      redirect_to my_enterprise_new_path unless action_name.in?(%w[new create]) && controller_name == "enterprises"
    else
      redirect_to my_enterprise_choices_path unless controller_name == "choices"
    end
  end

  def enterprise = Current.enterprise
end
