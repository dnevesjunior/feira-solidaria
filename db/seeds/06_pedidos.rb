# Pedidos fictícios em estados diferentes, para o painel ter o que mostrar.
# Compradores inventados; telefones no bloco 13 98888-00NN.
def pedido(loja, itens, nome:, fone:, obs: nil, &block)
  enterprise = Enterprise.find_by!(name: loja)
  products = itens.to_h { |name, qty| [ enterprise.products.find_by!(name:), qty ] }
  order = Order.build_from_cart_group(enterprise:, items: products, buyer_name: nome, buyer_phone: fone, buyer_note: obs)
  order.save!
  block&.call(order)
  order
end

if Order.none?
  pedido("Doces da Cida", { "Bolo de fubá com goiabada" => 1, "Pé de moleque" => 2 }, nome: "Ana Paula", fone: "13 98888-0001", obs: "Para sábado, retiro na feira.") { |o| o.route! }
  pedido("Doces da Cida", { "Bolo de fubá com goiabada" => 2 }, nome: "Carlos", fone: "13 98888-0002") { |o| o.route!; o.confirm! }
  pedido("Doces da Cida", { "Pé de moleque" => 5 }, nome: "Beatriz", fone: "13 98888-0003") { |o| o.route!; o.confirm!; o.complete!(outcome: "full") }
  pedido("Pães da Rosângela", { "Pão de queijo" => 2, "Broa de fubá" => 1 }, nome: "Dona Lourdes", fone: "13 98888-0004", obs: "Sem lactose, se tiver.")
  pedido("Pães da Rosângela", { "Pão de forma integral" => 3 }, nome: "Marcos", fone: "13 98888-0005") { |o| o.route!; o.refuse! }
  pedido("Sabão da Terra", { "Sabão em barra" => 4 }, nome: "Ana Paula", fone: "13 98888-0001") { |o| o.route!; o.confirm!; o.complete!(outcome: "partial", note: "levou 3, um ficou para a próxima") }
end
puts "  #{Order.count} pedidos (#{Order.open.count} abertos)"
