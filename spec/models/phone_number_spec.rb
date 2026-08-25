require "rails_helper"

RSpec.describe PhoneNumber do
  it "normaliza formatos comuns para E.164" do
    expect(PhoneNumber.normalize("(13) 99999-0001")).to eq("+5513999990001")
    expect(PhoneNumber.normalize("13 99999 0001")).to eq("+5513999990001")
    expect(PhoneNumber.normalize("013999990001")).to eq("+5513999990001")
    expect(PhoneNumber.normalize("+55 13 99999-0001")).to eq("+5513999990001")
    expect(PhoneNumber.normalize("5513999990001")).to eq("+5513999990001")
    expect(PhoneNumber.normalize("13 3333-0001")).to eq("+551333330001")
  end

  it "não confunde DDD 55 com o DDI" do
    expect(PhoneNumber.normalize("55 99999-0001")).to eq("+5555999990001")
  end

  it "devolve nil para o que não é telefone" do
    expect(PhoneNumber.normalize("abc")).to be_nil
    expect(PhoneNumber.normalize("999")).to be_nil
    expect(PhoneNumber.normalize("")).to be_nil
    expect(PhoneNumber.normalize(nil)).to be_nil
  end

  it "formata para leitura" do
    expect(PhoneNumber.format("+5513999990001")).to eq("(13) 99999-0001")
    expect(PhoneNumber.format("+551333330001")).to eq("(13) 3333-0001")
  end
end
