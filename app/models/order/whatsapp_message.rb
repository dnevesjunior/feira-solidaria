# frozen_string_literal: true

# Mensagem estruturada para o wa.me (Epic 3.3): legível no celular sem rolar
# muito, com tudo que a loja precisa para responder na própria conversa.
class Order::WhatsappMessage
  MAX_LENGTH = 1_500

  def initialize(order, order_url)
    @order = order
    @order_url = order_url
  end

  def to_s
    lines = [
      "Pedido #{@order.code} — Feira Solidária",
      "Olá! Quero encomendar:"
    ]
    @order.items.each do |item|
      lines << "• #{item.quantity} × #{item.product_name} (#{item.unit_price}/#{item.sale_unit}) = #{item.subtotal}"
    end
    lines << "Total: #{@order.total}"
    lines << "Nome: #{@order.buyer_name}"
    lines << "Obs.: #{note_for(lines)}" if @order.buyer_note.present?
    lines << "Acompanhe: #{@order_url}"
    lines.join("\n")
  end

  def url
    "https://wa.me/#{@order.enterprise.whatsapp.delete('+')}?text=#{ERB::Util.url_encode(to_s)}"
  end

  private

  def note_for(lines)
    budget = MAX_LENGTH - lines.sum(&:length) - lines.size - @order_url.length - 30
    @order.buyer_note.truncate([ budget, 40 ].max)
  end
end
