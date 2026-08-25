require "rails_helper"

RSpec.describe Event do
  let(:user) { create_user }
  let!(:event) { Event.record("user.password_reset_by_coordination", subject: user) }

  describe "append-only (ADR 0006)" do
    it "não pode ser alterado pelo ActiveRecord" do
      expect { event.update!(kind: "user.created") }.to raise_error(ActiveRecord::ReadOnlyRecord)
    end

    it "não pode ser apagado pelo ActiveRecord" do
      expect { event.destroy! }.to raise_error(ActiveRecord::ReadOnlyRecord)
    end

    it "não pode ser alterado nem por SQL direto — o trigger do banco recusa" do
      expect { Event.where(id: event.id).update_all(kind: "x") }
        .to raise_error(ActiveRecord::StatementInvalid, /append-only/)
    end

    it "não pode ser apagado nem por SQL direto" do
      expect { Event.where(id: event.id).delete_all }
        .to raise_error(ActiveRecord::StatementInvalid, /append-only/)
    end

    it "não pode ser apagado nem por DELETE sem WHERE" do
      expect { ActiveRecord::Base.connection.execute("DELETE FROM events") }
        .to raise_error(ActiveRecord::StatementInvalid, /append-only/)
    end
  end

  describe "catálogo" do
    it "recusa tipo não registrado" do
      expect { Event.record("pedido.inventado", subject: user) }
        .to raise_error(ActiveRecord::RecordInvalid, /Catalog/)
    end

    it "recusa chave de payload fora da allowlist (barreira contra dado pessoal)" do
      expect { Event.record("user.created", subject: user, payload: { phone: "+5513999990001" }) }
        .to raise_error(ActiveRecord::RecordInvalid, /chaves não permitidas/)
    end
  end

  it "registra ator, alvo e momento" do
    Current.session = user.sessions.create!
    e = Event.record("user.password_reset_by_coordination", subject: user, actor: Current.user)
    expect(e.actor).to eq(user)
    expect(e.subject).to eq(user)
    expect(e.occurred_at).to be_within(2.seconds).of(Time.current)
  end
end
