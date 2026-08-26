# Painel de pedidos do empreendimento (Epic 3.5): o que está aberto e o que
# precisa ser feito hoje. Sem métrica, sem funil, sem gráfico, sem meta.
class MyEnterprise::OrdersController < MyEnterprise::BaseController
  before_action :set_order, except: :index

  def index
    orders = enterprise.orders.includes(:items).recent_first
    @received = orders.select(&:received?)
    @confirmed = orders.select(&:confirmed?)
    @closed = orders.select { |o| !o.open? }.first(50)
    @warnings = Order::CapacityWarning.for(enterprise)
  end

  def show
    @warnings = Order::CapacityWarning.for(enterprise).select { |w| @order.items.any? { |i| i.product_id == w.product.id } }
  end

  def confirm = transition { @order.confirm!; t("orders.confirmed") }
  def refuse = transition { @order.refuse!; t("orders.refused") }
  def cancel = transition { @order.cancel!; t("orders.cancelled") }

  def complete
    transition { @order.complete!(outcome: params[:outcome], note: params[:outcome_note]); t("orders.completed") }
  end

  private

  def set_order
    @order = enterprise.orders.includes(:items).find_by!(token: params[:id])
  end

  def transition
    notice = yield
    redirect_to my_enterprise_order_path(@order), notice:
  rescue Order::InvalidTransition, ArgumentError
    redirect_to my_enterprise_order_path(@order), alert: t("orders.invalid_transition")
  end
end
