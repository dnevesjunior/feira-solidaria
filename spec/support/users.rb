module UserHelpers
  def create_user(name: "Maria das Graças Oliveira", phone: "13 90000-0001", password: "feira1234", **attrs)
    User.create!(name:, phone:, password:, **attrs)
  end

  # Request specs: entra pela rota real, sem atalho.
  def sign_in_as(user, password: "feira1234")
    post session_path, params: { phone: user.phone, password: password }
  end
end

RSpec.configure { |c| c.include UserHelpers }
