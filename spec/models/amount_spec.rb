require "rails_helper"

RSpec.describe Amount do
  describe "unidades distintas (CLAUDE.md §3.1)" do
    it "não soma reais com chiquinhos" do
      expect { Amount.brl(1000) + Amount.chiquinho(1000) }.to raise_error(Amount::UnitMismatch)
    end

    it "não subtrai entre unidades" do
      expect { Amount.chiquinho(5) - Amount.brl(5) }.to raise_error(Amount::UnitMismatch)
    end

    it "não ordena entre unidades" do
      expect { Amount.brl(1) < Amount.chiquinho(2) }.to raise_error(Amount::UnitMismatch)
    end

    it "considera valores de unidades diferentes como não iguais, sem levantar" do
      expect(Amount.brl(1)).not_to eq(Amount.chiquinho(1))
    end

    it "soma dentro da mesma unidade" do
      expect(Amount.brl(1000) + Amount.brl(250)).to eq(Amount.brl(1250))
      expect(Amount.chiquinho(3) + Amount.chiquinho(4)).to eq(Amount.chiquinho(7))
    end

    it "não expõe nenhuma conversão" do
      amount = Amount.brl(100)
      %i[convert exchange to_brl to_chiquinho rate].each do |method|
        expect(amount).not_to respond_to(method)
      end
    end
  end

  describe "só inteiros" do
    it "recusa Float" do
      expect { Amount.brl(10.0) }.to raise_error(ArgumentError, /Integer/)
    end

    it "recusa BigDecimal e String" do
      expect { Amount.brl(BigDecimal("10")) }.to raise_error(ArgumentError)
      expect { Amount.brl("10") }.to raise_error(ArgumentError)
    end

    it "só multiplica por Integer" do
      expect(Amount.brl(250) * 3).to eq(Amount.brl(750))
      expect { Amount.brl(250) * 1.5 }.to raise_error(ArgumentError)
    end

    it "recusa unidade desconhecida" do
      expect { Amount.new(1, :usd) }.to raise_error(ArgumentError, /unidade/)
    end
  end

  describe "formatação pt-BR com aritmética inteira" do
    it "formata reais" do
      expect(Amount.brl(123_456).to_s).to eq("R$ 1.234,56")
      expect(Amount.brl(5).to_s).to eq("R$ 0,05")
      expect(Amount.brl(-1000).to_s).to eq("-R$ 10,00")
      expect(Amount.brl(100_000_000).to_s).to eq("R$ 1.000.000,00")
    end

    it "formata chiquinhos" do
      expect(Amount.chiquinho(1).to_s).to eq("1 Chiquinho")
      expect(Amount.chiquinho(1500).to_s).to eq("1.500 Chiquinhos")
    end
  end

  it "é imutável e serve de chave de hash" do
    amount = Amount.brl(1)
    expect(amount).to be_frozen
    expect({ amount => :x }[Amount.brl(1)]).to eq(:x)
  end
end
