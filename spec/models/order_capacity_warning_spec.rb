require "rails_helper"

RSpec.describe Order::CapacityWarning do
  let(:loja) { publish(create_enterprise) }
  let(:bolo) { create_product(loja, name: "Bolo", capacity_quantity: 10, capacity_period: "week") }
  let(:doce) { create_product(loja, name: "Doce", capacity_quantity: nil) }

  it "avisa quando pedidos abertos da semana passam da capacidade, sem bloquear nada" do
    expect(described_class.for(loja)).to be_empty
    create_order(loja, items: { bolo => 6 })
    expect(described_class.for(loja)).to be_empty
    segundo = create_order(loja, items: { bolo => 6, doce => 50 })
    expect(segundo).to be_persisted # nada impede o pedido
    warnings = described_class.for(loja)
    expect(warnings.size).to eq(1)
    expect(warnings.first.product).to eq(bolo)
    expect(warnings.first.open_quantity).to eq(12)
    expect(warnings.first.weekly_capacity).to eq(10)
  end

  it "ignora pedidos fechados e antigos" do
    create_order(loja, items: { bolo => 20 }).complete!(outcome: "full")
    velho = create_order(loja, items: { bolo => 20 })
    velho.update_columns(created_at: 10.days.ago)
    expect(described_class.for(loja)).to be_empty
  end
end
