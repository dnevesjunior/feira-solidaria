require "rails_helper"

RSpec.describe Order do
  let(:loja) { publish(create_enterprise) }
  let(:bolo) { create_product(loja, name: "Bolo de fubá", price: "35,00") }
  let(:doce) { create_product(loja, name: "Pé de moleque", price: "8,00", sale_unit: "pacote") }

  it "é escopado, tem token não sequencial e congela preço e total" do
    expect(Order).to include(EnterpriseScoped)
    order = create_order(loja, items: { bolo => 2, doce => 1 })
    expect(order.token.length).to eq(20)
    expect(order.token).not_to match(/\A\d+\z/)
    expect(order.code).to match(/\AF-[A-Z0-9]{5}\z/)
    expect(order.total).to eq(Amount.brl(7800))

    bolo.price_input = "50,00"
    bolo.save!
    expect(order.reload.items.find_by(product: bolo).unit_price).to eq(Amount.brl(3500))
    expect(order.total).to eq(Amount.brl(7800))
    bolo.destroy!
    expect(order.reload.items.first.product_name).to eq("Bolo de fubá")
  end

  it "só guarda nome e WhatsApp do comprador — nada mais" do
    expect(Order.column_names).not_to include("cpf", "address", "email", "birth_date", "endereco")
    order = create_order(loja, items: { bolo => 1 }, buyer_phone: "(13) 98888-0001")
    expect(order.buyer_phone).to eq("+5513988880001")
    invalid = Order.build_from_cart_group(enterprise: loja, items: { bolo => 1 }, buyer_name: "A", buyer_phone: "12", buyer_note: nil)
    expect(invalid).not_to be_valid
  end

  it "registra order.created sem dado pessoal no payload" do
    order = create_order(loja, items: { bolo => 2 }, buyer_note: "para sábado")
    event = Event.find_by!(kind: "order.created", subject: order)
    expect(event.payload).to eq({ "item_count" => 1, "total_cents" => 7000 })
    expect(Event.where(subject: order).map { |e| e.payload.to_s }.join).not_to include("Ana", "sábado", "98888")
  end

  it "segue o ciclo manual e recusa transições inválidas" do
    order = create_order(loja, items: { bolo => 1 })
    expect(order).to be_received
    expect(order).to be_open
    order.confirm!
    expect(order.confirmed_at).to be_present
    expect { order.confirm! }.to raise_error(Order::InvalidTransition)
    order.complete!(outcome: "partial", note: "faltou um")
    expect(order.reload).to be_completed
    expect(order.closed_at).to be_present
    expect(order.outcome).to eq("partial")
    expect { order.cancel! }.to raise_error(Order::InvalidTransition)
    expect(Event.where(subject: order).pluck(:kind)).to include("order.confirmed", "order.completed", "order.outcome_recorded")
    expect(Event.find_by(kind: "order.completed", subject: order).payload).to eq({ "outcome" => "partial" })
  end

  it "pode ser recusado ou cancelado enquanto aberto" do
    expect(create_order(loja, items: { bolo => 1 }).tap(&:refuse!)).to be_refused
    expect(create_order(loja, items: { bolo => 1 }).tap(&:confirm!).tap(&:cancel!)).to be_cancelled
  end

  it "roteado = comprador abriu o WhatsApp; idempotente" do
    order = create_order(loja, items: { bolo => 1 })
    expect(order).not_to be_routed
    order.route!
    order.route!
    expect(order.reload).to be_routed
    expect(Event.where(kind: "order.routed", subject: order).count).to eq(1)
  end

  describe "expurgo (ADR 0016)" do
    it "apaga nome, telefone e observação sem mexer no estado" do
      order = create_order(loja, items: { bolo => 1 }, buyer_note: "obs")
      order.complete!(outcome: "full")
      order.purge_buyer_data!
      order.reload
      expect([ order.buyer_name, order.buyer_phone, order.buyer_note ]).to all(be_nil)
      expect(order).to be_completed
      expect(order.total).to eq(Amount.brl(3500))
      expect(order).to be_valid
    end

    it "seleciona fechados há mais de 90 dias e abertos há mais de 180" do
      recente = create_order(loja, items: { bolo => 1 }).tap { |o| o.complete!(outcome: "full") }
      antigo = create_order(loja, items: { bolo => 1 }).tap { |o| o.complete!(outcome: "full") }
      antigo.update_columns(closed_at: 91.days.ago)
      quase = create_order(loja, items: { bolo => 1 }).tap { |o| o.complete!(outcome: "full") }
      quase.update_columns(closed_at: 89.days.ago)
      aberto_velho = create_order(loja, items: { bolo => 1 })
      aberto_velho.update_columns(created_at: 181.days.ago)

      expect(Order.due_for_purge).to contain_exactly(antigo, aberto_velho)
      expect(PurgeBuyerDataJob.perform_now).to eq(2)
      expect(recente.reload.buyer_name).to eq("Ana")
      expect(aberto_velho.reload.buyer_name).to be_nil
      expect(aberto_velho).to be_received
    end
  end
end
