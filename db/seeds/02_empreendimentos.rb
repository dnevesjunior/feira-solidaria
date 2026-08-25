# Empreendimentos fictícios, plausíveis de uma feira artesanal da Baixada
# Santista (Epic 0.9). Nenhum é real. Imagens são geradas na hora com vips
# (cor sólida + inicial) — não há foto de ninguém aqui.
require "vips"

def seed_image(label, color:, width:, height:)
  img = Vips::Image.black(width, height).draw_rect(color, 0, 0, width, height, fill: true)
  img = img.bandjoin([ img, img ]) if img.bands == 1
  # Faixa mais clara para dar textura ao placeholder.
  img = img.draw_rect(color.map { |c| [ c + 40, 255 ].min }, 0, (height * 0.7).to_i, width, (height * 0.3).to_i, fill: true)
  { io: StringIO.new(img.write_to_buffer(".jpg", Q: 80)), filename: "#{label}.jpg", content_type: "image/jpeg" }
end

def para(text) = { "type" => "paragraph", "data" => { "text" => text } }
def header(text) = { "type" => "header", "data" => { "text" => text, "level" => 2 } }
def lista(*items) = { "type" => "list", "data" => { "style" => "unordered", "items" => items.map { |i| { "content" => i, "items" => [] } } } }

LOJAS = [
  {
    name: "Doces da Cida", whatsapp: "13 90000-0003", member_phone: "13 90000-0003",
    short_description: "Doces caseiros e bolos por encomenda", neighborhood: "Vila Gilda", color: [ 160, 60, 40 ],
    blocks: [
      header("Quem somos"),
      para("Sou a Cida. Faço doces desde que aprendi com minha mãe, em Santos, há mais de trinta anos. Hoje trabalho com minha filha e minha nora."),
      para("Tudo é feito na nossa cozinha, com fruta da região quando é época: banana, goiaba, manga."),
      header("O que fazemos"),
      lista("Bolo de fubá com goiabada", "Pé de moleque", "Doce de banana em barra", "Brigadeiro de panela"),
      para("Encomendas com dois dias de antecedência. Retirada na feira ou combinada pelo WhatsApp.")
    ]
  },
  {
    name: "Bordados do Dique", whatsapp: "13 90000-0001", member_phone: "13 90000-0001",
    short_description: "Panos de prato, toalhas e caminhos de mesa bordados à mão", neighborhood: "Dique da Vila Gilda", color: [ 40, 90, 140 ],
    blocks: [
      header("Nossa história"),
      para("Somos um grupo de cinco mulheres do Dique. Começamos bordando para casa e hoje bordamos para vender, juntas, dividindo o que entra."),
      para("Cada peça leva de dois dias a uma semana. Aceitamos encomenda com nome bordado."),
      { "type" => "quote", "data" => { "text" => "Bordar é conversar com as mãos.", "caption" => "Dona Graça" } }
    ]
  },
  {
    name: "Sabão da Terra", whatsapp: "13 90000-0002", member_phone: "13 90000-0002",
    short_description: "Sabão e sabonete artesanal com óleo reaproveitado", neighborhood: "Rádio Clube", color: [ 70, 120, 70 ],
    blocks: [
      para("O Zé Carlos recolhe óleo de cozinha usado nas casas do bairro e transforma em sabão em barra e sabonete com ervas."),
      para("O óleo que iria pro esgoto vira produto. Cada litro recolhido é um litro a menos no rio."),
      lista("Sabão em barra (pacote com 5)", "Sabonete de erva-doce", "Sabonete de alecrim")
    ]
  },
  {
    name: "Pães da Rosângela", whatsapp: "13 90000-0004", member_phone: "13 90000-0004",
    short_description: "Pão caseiro, rosca e broa, assados no dia", neighborhood: "Areia Branca", color: [ 170, 120, 50 ],
    blocks: [
      para("Pão de fermentação longa, assado de madrugada para chegar fresco na feira."),
      lista("Pão de forma integral", "Rosca de coco", "Broa de fubá", "Pão de queijo (congelado)")
    ]
  },
  {
    name: "Artesanato Ramos", whatsapp: "13 90000-0005", member_phone: "13 90000-0005",
    short_description: "Cestaria e utilidades em fibra e madeira reaproveitada", neighborhood: "Vila Gilda", color: [ 110, 80, 60 ],
    blocks: [
      para("Antônio faz cestos, porta-panelas e bancos com madeira de descarte e fibra de bananeira."),
      para("Peças sob medida podem ser combinadas pelo WhatsApp.")
    ]
  }
].freeze

LOJAS.each do |attrs|
  enterprise = Enterprise.find_by(name: attrs[:name])
  unless enterprise
    enterprise = Enterprise.new(attrs.slice(:name, :whatsapp, :short_description, :neighborhood))
    enterprise.profile_image.attach(seed_image("perfil", color: attrs[:color], width: 600, height: 600))
    enterprise.cover_image.attach(seed_image("capa", color: attrs[:color], width: 1600, height: 840))
    enterprise.content = { "blocks" => attrs[:blocks] }
    enterprise.save!
    enterprise.memberships.create!(user: User.find_by_phone(attrs[:member_phone]))
    enterprise.publish!
  end
  puts "  #{enterprise.name} — /#{enterprise.slug}"
end
