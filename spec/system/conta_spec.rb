require "rails_helper"

RSpec.describe "Minha conta", type: :system do
  let!(:user) { create_user(name: "Aparecida Ferreira", phone: "13 90000-0003", password: "feira1234") }

  it "entra, troca a senha e sai, tudo em português" do
    visit new_session_path
    fill_in "Seu telefone (o do WhatsApp)", with: "(13) 90000-0003"
    fill_in "Sua senha", with: "feira1234"
    click_button "Entrar"
    expect(page).to have_content("Aparecida Ferreira")

    click_link "Minha conta"
    fill_in "Senha atual", with: "feira1234"
    fill_in "Nova senha", with: "bolo de fubá quente"
    fill_in "Repita a nova senha", with: "bolo de fubá quente"
    click_button "Trocar senha"
    expect(page).to have_content("Senha trocada")

    click_button "Sair"
    expect(page).to have_content("Você saiu")

    fill_in "Seu telefone (o do WhatsApp)", with: "13900000003"
    fill_in "Sua senha", with: "bolo de fubá quente"
    click_button "Entrar"
    expect(page).to have_content("Aparecida Ferreira")
  end
end
