# frozen_string_literal: true

# Item de pedido com nome, unidade e preço CONGELADOS no momento do pedido
# (Epic 3.2): o produto muda depois; o pedido não.
class OrderItem < ApplicationRecord
  belongs_to :order
  belongs_to :product, optional: true

  attribute :unit_price_cents, :amount, unit: :brl
  def unit_price = unit_price_cents

  validates :product_name, :sale_unit, presence: true
  validates :quantity, numericality: { only_integer: true, greater_than: 0, less_than: 100 }
  validate { errors.add(:unit_price_cents, "precisa ser positivo") unless unit_price&.positive? }

  def subtotal = unit_price * quantity
end
