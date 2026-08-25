require "rails_helper"

RSpec.describe Enterprise::Slug do
  it "gera endereço falável: sem acento, sem número, sem hífen duplo, curto" do
    expect(described_class.generate("Doces da Cida")).to eq("doces-da-cida")
    expect(described_class.generate("Pães & Bolos da Rosângela")).to eq("paes-bolos-da-rosangela")
    expect(described_class.generate("Artesanato 2 Irmãs")).to eq("artesanato-irmas")
    expect(described_class.generate("  Sabão -- da  Terra ")).to eq("sabao-da-terra")
    expect(described_class.generate("Bordados do Dique da Vila Gilda e Arredores").length).to be <= 30
    expect(described_class.generate("Bordados do Dique da Vila Gilda e Arredores")).not_to end_with("-")
  end

  it "não usa caminhos da aplicação" do
    expect(described_class.generate("Entrar")).to eq("loja")
    expect(described_class.reserved?("minha-loja")).to be(true)
  end

  it "desempata sem número" do
    taken = ->(s) { %w[doces-da-cida doces-da-cida-da-feira].include?(s) }
    expect(described_class.generate("Doces da Cida", taken:)).to eq("doces-da-cida-solidaria")
  end

  it "valida o formato" do
    expect(described_class.valid?("doces-da-cida")).to be(true)
    expect(described_class.valid?("doces--da")).to be(false)
    expect(described_class.valid?("doces-1")).to be(false)
    expect(described_class.valid?("Doces")).to be(false)
    expect(described_class.valid?("a" * 31)).to be(false)
  end
end
