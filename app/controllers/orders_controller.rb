# Página do pedido para o comprador (Epic 3.4): endereço por token, estado,
# e o botão que abre o WhatsApp — o toque é o que registra "roteado".
class OrdersController < ApplicationController
  allow_unauthenticated_access
  before_action :set_order, only: %i[ show whatsapp ]

  def show
    @message = @order.whatsapp_message(order_url(@order))
    @warnings = []
  end

  def whatsapp
    @order.route!
    redirect_to @order.whatsapp_message(order_url(@order)).url, allow_other_host: true
  end

  def sent
    tokens = Array(session[:sent_order_tokens])
    @orders = Order.where(token: tokens).includes(:enterprise, :items)
    redirect_to cart_path if @orders.empty?
  end

  private

  def set_order
    @order = Order.includes(:enterprise, :items).find_by!(token: params[:token])
  end
end
