require "rails_helper"

RSpec.describe Cart do
  let(:cida) { publish(create_enterprise(name: "Doces da Cida", whatsapp: "13 99999-0001")) }
  let(:ze) { publish(create_enterprise(name: "Sabão da Terra", whatsapp: "13 99999-0002")) }
  let(:bolo) { create_product(cida, name: "Bolo", price: "35,00") }
  let(:sabao) { create_product(ze, name: "Sabão", price: "15,00") }
  let(:session) { {} }
  let(:cart) { Cart.new(session) }

  it "guarda na sessão, agrupa por empreendimento e soma em Amount" do
    cart.add(bolo.id, 2)
    cart.add(sabao.id)
    expect(session[:cart]).to eq({ bolo.id.to_s => 2, sabao.id.to_s => 1 })
    expect(cart.count).to eq(3)
    expect(cart.groups.keys).to contain_exactly(cida, ze)
    expect(cart).to be_multiple_enterprises
    expect(cart.total).to eq(Amount.brl(8500))
  end

  it "descarta produto pausado, rascunho ou de loja não publicada" do
    pausado = create_product(cida, name: "Pausado").tap(&:pause!)
    rascunho = create_product(cida, name: "Rascunho", publish: false, photo: false)
    outra = create_enterprise(name: "Não publicada", whatsapp: "13 99999-0009")
    escondido = create_product(outra, name: "Escondido")
    [ pausado, rascunho, escondido, bolo ].each { |p| cart.add(p.id) }
    expect(cart.lines.map(&:product)).to eq([ bolo ])
    expect(session[:cart].keys).to eq([ bolo.id.to_s ])
  end

  it "limita quantidades e remove ao zerar" do
    cart.add(bolo.id, 500)
    expect(cart.lines.first.quantity).to eq(99)
    cart.set(bolo.id, 0)
    expect(cart).to be_empty
  end
end
