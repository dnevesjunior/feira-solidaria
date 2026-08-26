module OrderHelpers
  def create_order(enterprise, items:, buyer_name: "Ana", buyer_phone: "13 98888-0001", buyer_note: nil)
    order = Order.build_from_cart_group(enterprise:, items:, buyer_name:, buyer_phone:, buyer_note:)
    order.save!
    order
  end
end

RSpec.configure { |c| c.include OrderHelpers }
