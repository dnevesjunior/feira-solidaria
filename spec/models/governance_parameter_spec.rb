require "rails_helper"

RSpec.describe Governance::Parameter do
  it "devolve o default declarado quando não há registro" do
    expect(described_class.value_for(:hub_ordering)).to eq("daily_rotation")
  end

  it "devolve o registro mais recente e não permite alterar registros" do
    described_class.create!(key: "hub_ordering", value: "daily_rotation", note: "inicial")
    p = described_class.create!(key: "hub_ordering", value: "daily_rotation")
    expect(described_class.value_for(:hub_ordering)).to eq("daily_rotation")
    expect { p.update!(value: "x") }.to raise_error(ActiveRecord::ReadOnlyRecord)
  end

  it "recusa chave desconhecida" do
    expect { described_class.value_for(:taxa) }.to raise_error(ArgumentError)
    expect(described_class.new(key: "taxa", value: 1)).not_to be_valid
  end
end
