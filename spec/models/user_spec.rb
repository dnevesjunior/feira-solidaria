require "rails_helper"

RSpec.describe User do
  it "normaliza o telefone e o usa como identificador único" do
    user = create_user(phone: "(13) 90000-0001")
    expect(user.phone).to eq("+5513900000001")
    expect(User.find_by_phone("13 90000 0001")).to eq(user)

    duplicate = User.new(name: "Outra", phone: "+55 13 90000-0001", password: "feira1234")
    expect(duplicate).not_to be_valid
    expect(duplicate.errors[:phone]).to be_present
  end

  it "recusa telefone inválido com mensagem em português" do
    user = User.new(name: "Maria", phone: "123", password: "feira1234")
    expect(user).not_to be_valid
    expect(user.errors.full_messages.join).to match(/Telefone/)
  end

  it "não exige e-mail" do
    expect(create_user(email: nil)).to be_persisted
    expect(create_user(phone: "13 90000-0002", email: "  ").email).to be_nil
  end

  it "exige senha de ao menos 8 caracteres, aceitando frases com espaço" do
    expect(User.new(name: "M", phone: "13 90000-0003", password: "curta")).not_to be_valid
    expect(User.new(name: "M", phone: "13 90000-0003", password: "pão de queijo")).to be_valid
  end

  it "registra o evento user.created sem dado pessoal no payload" do
    user = create_user
    event = Event.find_by!(kind: "user.created", subject: user)
    expect(event.payload).to eq({})
  end
end
