require "rails_helper"

RSpec.describe "Entrar" do
  let!(:user) { create_user(phone: "13 90000-0001", password: "pão de queijo") }

  it "entra com telefone em qualquer formato e senha" do
    post session_path, params: { phone: "(13) 90000-0001", password: "pão de queijo" }
    expect(response).to redirect_to(root_path)
    follow_redirect!
    expect(response.body).to include("Olá, Maria", "Minha loja")
  end

  it "recusa senha errada com mensagem em português" do
    post session_path, params: { phone: "13900000001", password: "errada12" }
    expect(response).to redirect_to(new_session_path)
    follow_redirect!
    expect(response.body).to include("não conferem")
  end

  it "limita tentativas por IP" do
    11.times { post session_path, params: { phone: "13900000001", password: "errada12" } }
    follow_redirect!
    expect(response.body).to include("Muitas tentativas")
  end

  it "não guarda IP nem user-agent na sessão (ADR 0007)" do
    post session_path, params: { phone: "13900000001", password: "pão de queijo" }
    expect(Session.column_names).not_to include("ip_address", "user_agent")
  end

  it "exige autenticação em /minha-conta" do
    get account_path
    expect(response).to redirect_to(new_session_path)
  end
end
