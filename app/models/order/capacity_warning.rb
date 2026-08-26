# frozen_string_literal: true

# Aviso ao empreendimento quando os pedidos abertos ultrapassam a capacidade
# declarada (Epic 3.6). Informa; nunca bloqueia, nunca esconde o produto,
# nunca avisa o comprador. Quem decide é quem produz.
class Order::CapacityWarning
  Warning = Data.define(:product, :open_quantity, :weekly_capacity)

  def self.for(enterprise, since: 7.days.ago)
    products = enterprise.products.where.not(capacity_quantity: nil).index_by(&:id)
    return [] if products.empty?

    open = OrderItem.joins(:order)
      .where(orders: { enterprise_id: enterprise.id, status: Order::OPEN_STATUSES })
      .where("orders.created_at >= ?", since)
      .where(product_id: products.keys)
      .group(:product_id).sum(:quantity)

    open.filter_map do |product_id, quantity|
      product = products[product_id]
      capacity = product.weekly_capacity
      Warning.new(product:, open_quantity: quantity, weekly_capacity: capacity) if capacity && quantity > capacity
    end
  end
end
