# Envio do pedido (Epic 3.2/3.3): um pedido por empreendimento, preços
# congelados, sem login, sem pagamento. Só nome e WhatsApp do comprador.
class CheckoutsController < ApplicationController
  allow_unauthenticated_access
  rate_limit to: 10, within: 1.hour, only: :create,
    with: -> { redirect_to new_checkout_path, alert: "Muitos pedidos deste aparelho. Espere um pouco e tente de novo." }
  before_action :ensure_cart

  def new
    @groups = cart.groups
  end

  def create
    @groups = cart.groups
    orders = @groups.map do |enterprise, lines|
      Order.build_from_cart_group(enterprise:, items: lines.to_h { |l| [ l.product, l.quantity ] },
        buyer_name: params[:buyer_name], buyer_phone: params[:buyer_phone], buyer_note: params[:buyer_note])
    end
    if orders.all?(&:valid?)
      Order.transaction { orders.each(&:save!) }
      cart.clear
      session[:sent_order_tokens] = orders.map(&:token)
      redirect_to(orders.one? ? order_path(orders.first) : sent_orders_path, notice: t("orders.sent"))
    else
      @order = orders.find(&:invalid?)
      render :new, status: :unprocessable_entity
    end
  end

  private

  def ensure_cart
    redirect_to cart_path, alert: t("cart.empty") if cart.empty?
  end
end
