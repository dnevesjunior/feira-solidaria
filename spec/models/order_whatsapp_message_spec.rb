require "rails_helper"

RSpec.describe Order::WhatsappMessage do
  let(:loja) { publish(create_enterprise(name: "Doces da Cida", whatsapp: "13 99999-0001")) }
  let(:bolo) { create_product(loja, name: "Bolo de fubá com goiabada", price: "35,00") }
  let(:doce) { create_product(loja, name: "Pé de moleque", price: "8,00", sale_unit: "pacote") }

  it "cabe no celular e tem tudo que a loja precisa" do
    order = create_order(loja, items: { bolo => 2, doce => 1 }, buyer_name: "Maria", buyer_note: "para sábado, se der")
    msg = described_class.new(order, "https://feira.exemplo/pedidos/#{order.token}")
    text = msg.to_s
    expect(text.lines.size).to be <= 9
    expect(text.length).to be < 400
    expect(text).to include("Pedido #{order.code}", "2 × Bolo de fubá com goiabada (R$ 35,00/unidade) = R$ 70,00",
      "1 × Pé de moleque (R$ 8,00/pacote) = R$ 8,00", "Total: R$ 78,00", "Nome: Maria", "Obs.: para sábado, se der",
      "Acompanhe: https://feira.exemplo/pedidos/#{order.token}")
    expect(msg.url).to start_with("https://wa.me/5513999990001?text=Pedido%20F-")
  end

  it "corta a observação para caber em 1.500 caracteres" do
    order = create_order(loja, items: { bolo => 1 }, buyer_note: "x" * 500)
    text = described_class.new(order, "https://feira.exemplo/pedidos/#{order.token}").to_s
    expect(text.length).to be <= described_class::MAX_LENGTH
    expect(text).to include("Acompanhe:")
  end
end
