require "rails_helper"

RSpec.describe PublishedEnterprisesQuery do
  before do
    %w[Doces\ da\ Cida Bordados\ do\ Dique Sabão\ da\ Terra Pães\ da\ Rosângela Artesanato\ Ramos Café\ do\ Zé].each_with_index do |name, i|
      publish(create_enterprise(name:, whatsapp: "13 99999-00#{format('%02d', i)}"))
    end
    create_enterprise(name: "Rascunho", whatsapp: "13 99999-0099")
  end

  it "só lista publicados" do
    expect(described_class.call.map(&:name)).not_to include("Rascunho")
    expect(described_class.call.size).to eq(6)
  end

  it "muda a ordem de um dia para o outro, e é igual dentro do mesmo dia" do
    a = described_class.call(date: Date.new(2026, 8, 25)).map(&:id)
    c = described_class.call(date: Date.new(2026, 8, 25)).map(&:id)
    expect(a).to eq(c)
    orders = (1..6).map { |d| described_class.call(date: Date.new(2026, 8, d)).map(&:id) }
    expect(orders.uniq.size).to be > 1
    expect(orders.map(&:sort).uniq.size).to eq(1)
  end

  it "não ordena por nome nem por cadastro" do
    ids = described_class.call(date: Date.new(2026, 8, 25)).map(&:id)
    expect(ids).not_to eq(ids.sort)
    names = described_class.call(date: Date.new(2026, 8, 25)).map(&:name)
    expect(names).not_to eq(names.sort)
  end

  it "busca por nome sem acento, mantendo a ordem rotativa" do
    expect(described_class.call(search: "paes").map(&:name)).to eq([ "Pães da Rosângela" ])
    expect(described_class.call(search: "DA").size).to eq(4)
  end

  it "lê a regra de ordenação do parâmetro de governança" do
    expect(Governance::Parameter).to receive(:value_for).with(:hub_ordering).and_return("daily_rotation")
    described_class.call
  end
end
