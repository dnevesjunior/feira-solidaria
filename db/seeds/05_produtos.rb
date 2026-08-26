# Produtos fictícios com preços e capacidades plausíveis (Epic 2). Capacidade
# por dia (pão), semana (doces), mês (bordado). Fotos geradas com vips.
def produto(loja, name, price, unit, cap, period, lead = nil, color: [ 120, 120, 120 ], desc: nil)
  enterprise = Enterprise.find_by!(name: loja)
  return if enterprise.products.exists?(name:)
  p = enterprise.products.new(name:, sale_unit: unit, capacity_quantity: cap, capacity_period: period, lead_time_days: lead, description: desc)
  p.price_input = price
  p.photos.attach(seed_image(name.parameterize, color:, width: 800, height: 800))
  p.save!
  p.publish!
end

produto "Doces da Cida", "Bolo de fubá com goiabada", "35,00", "unidade", 10, "week", 2, color: [ 200, 150, 60 ], desc: "Bolo caseiro de 1 kg. Encomende com dois dias."
produto "Doces da Cida", "Pé de moleque", "8,00", "pacote", 40, "week", nil, color: [ 140, 90, 40 ], desc: "Pacote com 6."
produto "Doces da Cida", "Doce de banana em barra", "12,00", "500 g", 20, "week", 3, color: [ 170, 110, 50 ]
produto "Bordados do Dique", "Pano de prato bordado", "25,00", "unidade", 30, "month", 7, color: [ 80, 120, 180 ], desc: "Bordado à mão. Aceitamos nome bordado."
produto "Bordados do Dique", "Caminho de mesa", "90,00", "unidade", 6, "month", 15, color: [ 60, 100, 160 ]
produto "Sabão da Terra", "Sabão em barra", "15,00", "pacote", 60, "week", nil, color: [ 100, 150, 100 ], desc: "Pacote com 5 barras. Óleo reaproveitado."
produto "Sabão da Terra", "Sabonete de erva-doce", "7,00", "unidade", 80, "week", nil, color: [ 130, 170, 120 ]
produto "Pães da Rosângela", "Pão de forma integral", "14,00", "unidade", 12, "day", nil, color: [ 190, 140, 70 ], desc: "Fermentação longa, assado de madrugada."
produto "Pães da Rosângela", "Pão de queijo", "18,00", "500 g", 8, "day", nil, color: [ 220, 190, 120 ], desc: "Congelado, pronto para assar."
produto "Pães da Rosângela", "Broa de fubá", "10,00", "unidade", 15, "day", nil, color: [ 210, 170, 90 ]
produto "Artesanato Ramos", "Cesto de fibra de bananeira", "60,00", "unidade", 4, "week", 5, color: [ 130, 100, 70 ]
produto "Artesanato Ramos", "Porta-panela de madeira", "20,00", "unidade", 10, "week", 3, color: [ 110, 80, 60 ]
# Um pausado, para a demonstração mostrar o estado.
Enterprise.find_by!(name: "Doces da Cida").products.find_by(name: "Doce de banana em barra")&.then { |p| p.pause! if p.published? }

puts "  #{Product.count} produtos (#{Product.published.count} no ar, #{Product.where(status: 'paused').count} em pausa)"
