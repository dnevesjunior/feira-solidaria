require "rails_helper"

# Critério de pronto do Epic 2: três produtos pelo celular, sem ajuda. Sem JS —
# o formulário não precisa de nenhum.
RSpec.describe "Cadastrar produtos", type: :system do
  let!(:user) { create_user(name: "Rosângela", phone: "13 90000-0004", password: "feira1234") }
  let!(:loja) { create_enterprise(user:, name: "Pães da Rosângela", whatsapp: "13 99999-0004") }

  it "cadastra três produtos com foto e publica um" do
    visit new_session_path
    fill_in "Seu telefone (o do WhatsApp)", with: "13900000004"
    fill_in "Sua senha", with: "feira1234"
    click_button "Entrar"

    click_link "Minha loja"
    click_link "Meus produtos"

    Tempfile.create([ "foto", ".jpg" ]) do |f|
      f.binmode; f.write(jpeg_upload.read); f.flush
      [ [ "Pão de forma integral", "14,00" ], [ "Pão de queijo", "18,00" ], [ "Broa de fubá", "10,00" ] ].each do |name, price|
        click_link "Cadastrar produto"
        fill_in "Nome do produto", with: name
        fill_in "Preço (em reais)", with: price
        attach_file "Fotos (até 4)", f.path
        click_button "Salvar produto"
        expect(page).to have_content("Produto salvo como rascunho")
      end
    end

    expect(page).to have_content("Rascunhos")
    expect(loja.products.count).to eq(3)
    within(:xpath, "//li[contains(., 'Broa de fubá')]") { click_button "Publicar" }
    expect(page).to have_content("Produto publicado")
    expect(page).to have_content("No ar")
  end
end
