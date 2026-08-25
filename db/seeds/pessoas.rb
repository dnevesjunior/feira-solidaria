# Pessoas fictícias da rede. Telefones no bloco 13 90000-00NN não existem.
# Senha de desenvolvimento para todas: feira1234
SENHA_DEV = "feira1234"

PESSOAS = [
  { name: "Coordenação da Feira", phone: "13 90000-0000" },
  { name: "Maria das Graças Oliveira", phone: "13 90000-0001" },
  { name: "José Carlos Santana", phone: "13 90000-0002" },
  { name: "Aparecida Ferreira", phone: "13 90000-0003" },
  { name: "Rosângela Lima dos Santos", phone: "13 90000-0004" },
  { name: "Antônio Batista Ramos", phone: "13 90000-0005" }
].freeze

PESSOAS.each do |attrs|
  user = User.find_by_phone(attrs[:phone]) || User.create!(attrs.merge(password: SENHA_DEV))
  puts "  #{user.name} — #{PhoneNumber.format(user.phone)}"
end
puts "  senha de todas: #{SENHA_DEV}"
