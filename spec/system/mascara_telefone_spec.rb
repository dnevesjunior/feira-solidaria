require "rails_helper"

RSpec.describe "Máscara de telefone", type: :system, js: true do
  let!(:user) { create_user(phone: "13 99999-0001", password: "feira1234") }

  it "formata enquanto digita e o login continua funcionando" do
    visit new_session_path
    campo = find_field("Seu telefone (o do WhatsApp)")

    campo.send_keys("13999990001")
    expect(campo.value).to eq("(13) 99999-0001")

    campo.set("")
    campo.send_keys("1333330001")
    expect(campo.value).to eq("(13) 3333-0001")

    # Colar "+55 13 99999-0001" (chega inteiro, num único evento input)
    page.execute_script(<<~JS, campo.native)
      const el = arguments[0]; el.value = "+55 13 99999-0001"; el.dispatchEvent(new Event("input", { bubbles: true }))
    JS
    expect(campo.value).to eq("(13) 99999-0001")

    fill_in "Sua senha", with: "feira1234"
    click_button "Entrar"
    expect(page).to have_content(user.name)
  end
end
