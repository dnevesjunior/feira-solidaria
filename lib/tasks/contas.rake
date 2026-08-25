# Contas são criadas e recuperadas pela coordenação, presencialmente (ADR 0007).
# Uso (as aspas importam por causa dos espaços):
#   bin/rails "contas:criar[13999990001,Maria das Graças Oliveira]"
#   bin/rails "contas:redefinir_senha[13999990001]"
namespace :contas do
  desc "Cria uma conta de membro com senha temporária: contas:criar[telefone,nome]"
  task :criar, [ :telefone, :nome ] => :environment do |_t, args|
    abort "uso: bin/rails \"contas:criar[telefone,nome]\"" if args[:telefone].blank? || args[:nome].blank?

    senha = senha_temporaria
    user = User.create!(name: args[:nome], phone: args[:telefone], password: senha)
    puts "Conta criada para #{user.name} (#{PhoneNumber.format(user.phone)})."
    puts "Senha temporária: #{senha}"
    puts "Peça para a pessoa trocar a senha em /minha-conta no primeiro acesso."
  end

  desc "Redefine a senha de um membro (registra evento): contas:redefinir_senha[telefone]"
  task :redefinir_senha, [ :telefone ] => :environment do |_t, args|
    user = User.find_by_phone(args[:telefone]) or abort "Nenhuma conta com o telefone #{args[:telefone].inspect}."

    senha = senha_temporaria
    User.transaction do
      user.update!(password: senha)
      Event.record("user.password_reset_by_coordination", subject: user)
    end
    puts "Senha de #{user.name} redefinida. Senha temporária: #{senha}"
    puts "Evento user.password_reset_by_coordination registrado."
  end

  def senha_temporaria
    # Legível em voz alta e no papel: sem 0/O, 1/l/I.
    alfabeto = ("a".."z").to_a + ("2".."9").to_a - %w[l o]
    Array.new(10) { alfabeto.sample }.join
  end
end
