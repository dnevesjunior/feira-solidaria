require "rails_helper"

# Critério de pronto do Epic 3: quem nunca viu a plataforma escolhe dois
# itens, envia, e o empreendimento recebe uma mensagem legível no WhatsApp;
# o empreendimento confirma e conclui pelo celular. Sem JS.
RSpec.describe "Pedido de ponta a ponta", type: :system do
  let!(:maria) { create_user(name: "Maria", phone: "13 90000-0001", password: "feira1234") }
  let!(:cida) { publish(create_enterprise(user: maria, name: "Doces da Cida", whatsapp: "13 99999-0001")) }
  let!(:bolo) { create_product(cida, name: "Bolo de fubá", price: "35,00") }
  let!(:doce) { create_product(cida, name: "Pé de moleque", price: "8,00", sale_unit: "pacote") }

  it "comprador envia; loja confirma e conclui" do
    visit "/doces-da-cida"
    within("#produto-#{bolo.id}") { click_button "Adicionar à cesta" }
    within("#produto-#{doce.id}") { click_button "Adicionar à cesta" }
    click_link "Cesta (2)"
    expect(page).to have_content("Total: R$ 43,00")
    click_link "Enviar pedido"
    fill_in "Seu nome", with: "Ana"
    fill_in "Seu WhatsApp (para a loja falar com você)", with: "13988880001"
    fill_in "Alguma observação? (opcional)", with: "Retiro na feira"
    click_button "Enviar pedido"

    expect(page).to have_content("Pedido enviado!")
    order = Order.last
    expect(page).to have_content("Pedido #{order.code}")
    expect(page).to have_button("Abrir no WhatsApp")
    mensagem = page.find("textarea.mensagem", visible: :all).value
    expect(mensagem).to match(/Pedido #{order.code}.*Total: R\$ 43,00.*Nome: Ana.*Retiro na feira/m)

    # A loja, no celular
    visit new_session_path
    fill_in "Seu telefone (o do WhatsApp)", with: "13900000001"
    fill_in "Sua senha", with: "feira1234"
    click_button "Entrar"
    click_link "Minha loja"
    click_link "Ver pedidos"
    expect(page).to have_content("Para responder")
    click_link "#{order.code} — Ana"
    click_button "Confirmar pedido"
    expect(page).to have_content("Confirmado pela loja")
    choose "Pago e entregue"
    click_button "Concluir pedido"
    expect(page).to have_content("Concluído")
    expect(order.reload.outcome).to eq("full")
  end
end
