require "rails_helper"

# Critério de pronto do Epic 1: uma pessoa, num celular modesto, cria a página,
# sobe uma foto de capa, escreve três parágrafos e publica.
RSpec.describe "Criar e publicar a vitrine pelo celular", type: :system, js: true do
  let!(:user) { create_user(name: "Aparecida Ferreira", phone: "13 90000-0003", password: "feira1234") }

  it "do login à página no ar" do
    visit new_session_path
    fill_in "Seu telefone (o do WhatsApp)", with: "13900000003"
    fill_in "Sua senha", with: "feira1234"
    click_button "Entrar"

    click_link "Minha loja"
    fill_in "Nome do empreendimento", with: "Doces da Cida"
    fill_in "WhatsApp para pedidos", with: "13999990001"
    click_button "Continuar"
    expect(page).to have_content("Editar minha página")

    # Foto de capa de 6 MB
    Tempfile.create([ "capa", ".jpg" ]) do |f|
      f.binmode
      f.write(jpeg_upload(width: 3000, height: 2000, megabytes: 6).read)
      f.flush
      attach_file "Foto de capa (aparece no topo da sua página)", f.path
      fill_in "Uma frase sobre o que você faz (opcional)", with: "Doces caseiros por encomenda"

      # Três parágrafos no EditorJS
      editor = find(".editor .codex-editor__redactor")
      editor.click
      find(".editor [contenteditable]", match: :first).send_keys("Fazemos doces desde 1998.", :enter, "Tudo feito em casa, com fruta da região.", :enter, "Encomende pelo WhatsApp.")
      click_button "Salvar"
      expect(page).to have_content("Página salva")
    end

    click_button "Publicar minha página"
    page.driver.browser.switch_to.alert.accept rescue nil
    expect(page).to have_content("Sua página está no ar")

    visit "/doces-da-cida"
    expect(page).to have_content("Doces da Cida")
    expect(page).to have_content("Fazemos doces desde 1998.")
    expect(page).to have_content("Encomende pelo WhatsApp.")
    expect(page).to have_css("img.capa")
  end
end
