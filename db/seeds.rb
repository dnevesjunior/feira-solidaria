# Seeds realistas, nunca reais (Epic 0.9). Nomes e telefones são fictícios por
# construção. Cada epic acrescenta um arquivo em db/seeds/.
# Em produção, `db:prepare` no primeiro boot chama os seeds: não abortar
# (derrubaria o contêiner), só pular.
if Rails.env.production? && ENV["SEED_PRODUCTION"] != "1"
  puts "Seeds são dados fictícios; em produção só rodam com SEED_PRODUCTION=1. Pulando."
else
  Dir[Rails.root.join("db/seeds/*.rb")].sort.each do |file|
    puts "→ #{File.basename(file)}"
    load file
  end
end
