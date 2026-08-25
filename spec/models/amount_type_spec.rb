require "rails_helper"

RSpec.describe Amount::Type do
  let(:brl) { ActiveRecord::Type.lookup(:amount, unit: :brl) }

  it "está registrado como :amount" do
    expect(brl).to be_a(Amount::Type)
  end

  it "persiste o inteiro e devolve Amount na unidade declarada" do
    expect(brl.serialize(Amount.brl(1500))).to eq(1500)
    expect(brl.deserialize(1500)).to eq(Amount.brl(1500))
    expect(brl.cast(1500)).to eq(Amount.brl(1500))
    expect(brl.cast("1500")).to eq(Amount.brl(1500))
    expect(brl.cast(nil)).to be_nil
    expect(brl.cast("")).to be_nil
  end

  it "recusa Amount de outra unidade" do
    expect { brl.cast(Amount.chiquinho(1)) }.to raise_error(Amount::UnitMismatch)
  end

  it "recusa Float" do
    expect { brl.cast(15.0) }.to raise_error(ArgumentError)
  end

  it "recusa unidade desconhecida na declaração" do
    expect { Amount::Type.new(unit: :usd) }.to raise_error(ArgumentError)
  end
end
