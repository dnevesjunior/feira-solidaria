require "rails_helper"

RSpec.describe Product do
  let(:enterprise) { create_enterprise }

  it "é escopado por empreendimento e guarda preço como Amount em centavos" do
    expect(Product).to include(EnterpriseScoped)
    p = create_product(enterprise, price: "12,50", publish: false, photo: false)
    expect(p.price).to eq(Amount.brl(1250))
    expect(p.price_cents).to eq(Amount.brl(1250))
    expect(p.read_attribute_before_type_cast(:price_cents)).to eq(1250)
    expect(Product.find(p.id).price).to eq(Amount.brl(1250))
    expect { p.price = Amount.chiquinho(1) }.to raise_error(ArgumentError)
    expect(p.price.to_s).to eq("R$ 12,50")
    expect(Product.columns_hash["price_cents"].sql_type).to eq("bigint")
  end

  it "recusa preço inválido com mensagem que ensina o formato" do
    p = Product.new(enterprise:, name: "Bolo")
    p.price_input = "12.50"
    expect(p).not_to be_valid
    expect(p.errors.full_messages.join).to include("12,50")
    p.price_input = "0"
    expect(p).not_to be_valid
  end

  it "salva rascunho só com nome e preço; publicar exige foto" do
    p = create_product(enterprise, publish: false, photo: false)
    expect(p).to be_draft
    expect { p.publish! }.to raise_error(ActiveRecord::RecordInvalid, /[Ff]oto/)
    p.photos.attach(jpeg_upload)
    p.save!
    p.publish!
    expect(p.reload).to be_published
  end

  it "pausa e despausa, registrando eventos" do
    p = create_product(enterprise)
    p.pause!
    expect(p.reload).to be_paused
    expect(Product.visible).not_to include(p)
    p.unpause!
    expect(Product.visible).to include(p)
    expect(Event.where(subject: p).pluck(:kind)).to include("product.published", "product.paused", "product.unpaused")
  end

  it "registra a mudança de capacidade com valor anterior e novo" do
    p = create_product(enterprise, capacity_quantity: 10, capacity_period: "week")
    p.update!(capacity_quantity: 30, capacity_period: "month")
    event = p.capacity_history.last
    expect(event.payload).to eq({ "quantity_from" => 10, "quantity_to" => 30, "period_from" => "week", "period_to" => "month" })
    p.update!(name: "Outro nome")
    expect(p.capacity_history.count).to eq(1)
    expect(Event.where(kind: "product.updated", subject: p).last.payload).to eq({ "changed" => [ "name" ] })
  end

  it "normaliza a capacidade para semana com aritmética inteira" do
    expect(Product::Capacity.weekly(5, "day")).to eq(35)
    expect(Product::Capacity.weekly(12, "week")).to eq(12)
    expect(Product::Capacity.weekly(52, "month")).to eq(12)
    expect(Product::Capacity.weekly(nil, "week")).to be_nil
    p = create_product(enterprise, capacity_quantity: 3, capacity_period: "day", publish: false, photo: false)
    expect(p.weekly_capacity).to eq(21)
    expect(p.capacity_label).to eq("3 unidade por dia")
  end

  it "limita fotos a quatro e exige imagem" do
    p = Product.new(enterprise:, name: "Bolo", price_input: "10")
    5.times { p.photos.attach(jpeg_upload) }
    expect(p).not_to be_valid
    expect(p.errors[:photos].join).to match(/máximo 4/)
  end

  it "não tem taxonomia: unidade de venda é texto curto, com lista sugerida" do
    expect(Product::SALE_UNITS).to include("dúzia", "kg", "pote")
    p = create_product(enterprise, sale_unit: "  cacho ", publish: false, photo: false)
    expect(p.sale_unit).to eq("cacho")
  end

  it "não expõe nada de estoque, rating ou desempenho" do
    %i[stock inventory rating reliability sales_count].each { |m| expect(Product.new).not_to respond_to(m) }
    expect(Product.column_names).not_to include("stock", "rating", "sales_count", "views_count")
  end
end
