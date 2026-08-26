require "rails_helper"

RSpec.describe "Catálogo e capacidade da rede" do
  let!(:cida) { publish(create_enterprise(name: "Doces da Cida", whatsapp: "13 99999-0001")) }
  let!(:rosangela) { publish(create_enterprise(name: "Pães da Rosângela", whatsapp: "13 99999-0002")) }
  let!(:ze) { publish(create_enterprise(name: "Sabão da Terra", whatsapp: "13 99999-0003")) }
  let!(:rascunho) { create_enterprise(name: "Loja Rascunho", whatsapp: "13 99999-0004") }

  before do
    create_product(cida, name: "Pão de queijo", capacity_quantity: 10, capacity_period: "week")
    create_product(rosangela, name: "Pão de Queijo", capacity_quantity: 3, capacity_period: "day")
    create_product(rosangela, name: "Broa", capacity_quantity: 52, capacity_period: "month")
    create_product(ze, name: "Sabão", capacity_quantity: nil)
    create_product(ze, name: "Sabonete pausado").pause!
    create_product(cida, name: "Rascunho", publish: false, photo: false)
    create_product(rascunho, name: "Produto de loja não publicada")
  end

  describe PublishedProductsQuery do
    it "lista só publicados de lojas publicadas, em ordem rotativa" do
      names = described_class.call.map(&:name)
      expect(names).to contain_exactly("Pão de queijo", "Pão de Queijo", "Broa", "Sabão")
      # Com poucos itens, duas datas podem coincidir por acaso; seis não.
      orders = (1..6).map { |d| described_class.call(date: Date.new(2026, 8, d)).map(&:id) }
      expect(orders.uniq.size).to be > 1
      expect(orders.map(&:sort).uniq.size).to eq(1)
    end

    it "busca por nome sem acento" do
      expect(described_class.call(search: "pao").map(&:name)).to contain_exactly("Pão de queijo", "Pão de Queijo")
    end

    it "não deriva nada de vendas, cliques ou perfil (CLAUDE.md §3.2)" do
      sql = described_class.call.to_sql
      expect(sql).to include(HubOrdering::DailyRotation.seed)
      expect(sql).not_to match(/page_views|events|orders|count\(|views/i)
    end
  end

  describe NetworkCapacityQuery do
    it "soma a capacidade semanal por produto, normalizando dia e mês" do
      rows = described_class.call.index_by { |r| r.name.downcase }
      expect(rows["pão de queijo"].weekly_total).to eq(10 + 3 * 7)
      expect(rows["pão de queijo"].enterprises).to eq(2)
      expect(rows["broa"].weekly_total).to eq(12)
      expect(rows.keys).not_to include("sabão", "sabonete pausado", "rascunho")
      expect(NetworkCapacityQuery.total(rows.values)).to eq(43)
    end
  end
end
