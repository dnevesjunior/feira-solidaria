require "rails_helper"

RSpec.describe "Amount.parse_brl" do
  it "lê preço em pt-BR sem ponto flutuante" do
    expect(Amount.parse_brl("12,50")).to eq(Amount.brl(1250))
    expect(Amount.parse_brl("R$ 1.234,5")).to eq(Amount.brl(123450))
    expect(Amount.parse_brl("12")).to eq(Amount.brl(1200))
    expect(Amount.parse_brl("0,05")).to eq(Amount.brl(5))
    expect(Amount.parse_brl(" 7 ")).to eq(Amount.brl(700))
  end

  it "recusa formatos ambíguos ou estrangeiros" do
    expect(Amount.parse_brl("12.50")).to be_nil
    expect(Amount.parse_brl("12,505")).to be_nil
    expect(Amount.parse_brl("abc")).to be_nil
    expect(Amount.parse_brl("")).to be_nil
    expect(Amount.parse_brl("-5")).to be_nil
  end
end
