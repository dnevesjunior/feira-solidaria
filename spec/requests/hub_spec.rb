require "rails_helper"

RSpec.describe "Hub" do
  before do
    publish(create_enterprise(name: "Doces da Cida", whatsapp: "13 99999-0001", neighborhood: "Vila Gilda"))
    create_enterprise(name: "Rascunho Secreto", whatsapp: "13 99999-0002")
    FairEvent.create!(starts_at: 2.days.from_now.change(hour: 9), place: "Praça da Igreja")
  end

  it "mostra a próxima feira e só os publicados, com a semente do dia" do
    get root_path
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Próxima feira", "Praça da Igreja", "Doces da Cida", "Vila Gilda")
    expect(response.body).not_to include("Rascunho Secreto")
    expect(response.body).to include(Date.current.iso8601)
  end

  it "busca por nome" do
    get root_path, params: { q: "cida" }
    expect(response.body).to include("Doces da Cida")
    get root_path, params: { q: "xyz" }
    expect(response.body).to include("Nenhum empreendimento com «xyz»")
  end

  it "não pede nada a terceiros" do
    get root_path
    external = response.body.scan(%r{(?:src|href)=["'](https?://[^"']+)}i).flatten.reject { |u| u.start_with?("http://www.example.com") }
    expect(external).to be_empty
  end
end
