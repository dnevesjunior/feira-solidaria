require "rails_helper"

RSpec.describe "Pedidos" do
  let(:maria) { create_user(name: "Maria", phone: "13 90000-0001") }
  let!(:cida) { publish(create_enterprise(user: maria, name: "Doces da Cida", whatsapp: "13 99999-0001")) }
  let!(:bolo) { create_product(cida, name: "Bolo de fubá", price: "35,00") }
  let!(:doce) { create_product(cida, name: "Pé de moleque", price: "8,00", sale_unit: "pacote") }

  def add(product, qty = 1) = post(cart_items_path, params: { product_id: product.id, quantity: qty })

  it "vitrine → cesta → enviar → página do pedido → WhatsApp, em menos de um minuto de cliques" do
    get "/doces-da-cida"
    expect(response.body).to include("Adicionar à cesta")

    add bolo, 2
    add doce
    get cart_path
    expect(response.body).to include("Bolo de fubá", "Total: R$ 78,00").and include("não cobra nada")

    post checkout_path, params: { buyer_name: "Ana", buyer_phone: "(13) 98888-0001", buyer_note: "para sábado" }
    order = Order.last
    expect(response).to redirect_to(order_path(order))
    follow_redirect!
    expect(response.body).to include("Pedido #{order.code}", "Recebido — aguardando", "Abrir no WhatsApp", "R$ 78,00")
    expect(order).not_to be_routed

    post order_whatsapp_path(order)
    expect(response).to redirect_to(%r{\Ahttps://wa\.me/5513999990001\?text=Pedido%20F-})
    expect(response.location).to include(ERB::Util.url_encode("2 × Bolo de fubá"), ERB::Util.url_encode("Total: R$ 78,00"), ERB::Util.url_encode("Nome: Ana"), order.token)
    expect(order.reload).to be_routed
    expect(Order::WhatsappMessage.new(order, order_url(order)).to_s.lines.size).to be <= 8
    get cart_path
    expect(response.body).to include("vazia")
  end

  it "itens de duas lojas viram dois pedidos, e o comprador sabe antes" do
    ze = publish(create_enterprise(name: "Sabão da Terra", whatsapp: "13 99999-0002"))
    sabao = create_product(ze, name: "Sabão", price: "15,00")
    add bolo
    add sabao
    get cart_path
    expect(response.body).to include("2 empreendimentos", "2 pedidos separados")
    get new_checkout_path
    expect(response.body).to include("Serão <strong>2 pedidos</strong>")

    expect { post checkout_path, params: { buyer_name: "Ana", buyer_phone: "13988880001" } }.to change(Order, :count).by(2)
    expect(response).to redirect_to(sent_orders_path)
    follow_redirect!
    expect(response.body.scan("Abrir no WhatsApp").size).to eq(2)
    expect(Order.pluck(:enterprise_id)).to contain_exactly(cida.id, ze.id)
  end

  it "não pede CPF, endereço, nascimento ou e-mail" do
    add bolo
    get new_checkout_path
    form = response.body[%r{<form.*</form>}m]
    expect(form.scan(/name="([^"]+)"/).flatten - [ "authenticity_token" ]).to contain_exactly("buyer_name", "buyer_phone", "buyer_note", "commit")
    fields = form.scan(/<(?:input|textarea|select)[^>]*>/).reject { |f| f.match?(/type="(hidden|submit)"/) }
    expect(fields.size).to eq(3) # nome, telefone, observação — e nada mais
  end

  it "valida nome e WhatsApp com mensagem em português" do
    add bolo
    post checkout_path, params: { buyer_name: "A", buyer_phone: "123" }
    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.body).to include("Seu WhatsApp")
    expect(Order.count).to eq(0)
  end

  it "não conta o token do pedido na telemetria" do
    order = create_order(cida, items: { bolo => 1 })
    get order_path(order), headers: { "User-Agent" => "Mozilla/5.0 (Linux; Android 10)" }
    expect(PageView.pluck(:path)).to include("/pedidos/:token")
    expect(PageView.pluck(:path).join).not_to include(order.token)
  end

  it "limita envios por IP" do
    11.times do
      add bolo
      post checkout_path, params: { buyer_name: "Ana", buyer_phone: "13988880001" }
    end
    follow_redirect!
    expect(response.body).to include("Muitos pedidos")
  end

  describe "painel do empreendimento" do
    let!(:order) { create_order(cida, items: { bolo => 2 }, buyer_name: "Ana", buyer_phone: "13 98888-0001") }

    it "lista por estado, mostra quem pediu, e o empreendimento confirma e conclui" do
      sign_in_as maria
      get my_enterprise_orders_path
      expect(response.body).to include("Para responder", order.code, "Ana", "não abriu o WhatsApp")
      expect(response.body[%r{<main.*</main>}m]).not_to match(/conversão|funil|\bmetas?\b|gráfico/i)

      post confirm_my_enterprise_order_path(order)
      expect(order.reload).to be_confirmed
      post complete_my_enterprise_order_path(order), params: { outcome: "full", outcome_note: "" }
      expect(order.reload).to be_completed
      expect(order.outcome).to eq("full")
      get my_enterprise_order_path(order)
      expect(response.body).to include("Pago e entregue")
    end

    it "pode recusar ou cancelar; transições inválidas não quebram" do
      sign_in_as maria
      post refuse_my_enterprise_order_path(order)
      expect(order.reload).to be_refused
      post confirm_my_enterprise_order_path(order)
      follow_redirect!
      expect(response.body).to include("não pode mudar")
    end

    it "avisa — e só avisa — quando pedidos abertos passam da capacidade declarada" do
      bolo.update!(capacity_quantity: 3, capacity_period: "week")
      add bolo, 5
      post checkout_path, params: { buyer_name: "Bia", buyer_phone: "13988880002" }
      expect(response).to have_http_status(:redirect) # o pedido é criado
      follow_redirect!
      expect(response.body).not_to match(/capacidade|declarou/i) # comprador não vê

      sign_in_as maria
      get my_enterprise_orders_path
      expect(response.body).to include("em pedidos abertos nesta semana", "declarou mais ou menos <strong>3 por semana</strong>", "quem decide aceitar é você")
      get "/doces-da-cida"
      expect(response.body).to include("Bolo de fubá") # produto não some
    end

    it "escopo: loja B não vê nem altera pedido de A" do
      jose = create_user(name: "José", phone: "13 90000-0002")
      publish(create_enterprise(user: jose, name: "Loja B", whatsapp: "13 99999-0009"))
      sign_in_as jose
      get my_enterprise_order_path(order)
      expect(response).to have_http_status(:not_found)
      post confirm_my_enterprise_order_path(order)
      expect(response).to have_http_status(:not_found)
      expect(order.reload).to be_received
    end
  end

  it "export inclui pedidos com itens, situação e desfecho" do
    sign_in_as maria
    order = create_order(cida, items: { bolo => 1 })
    order.complete!(outcome: "partial", note: "faltou")
    get my_enterprise_export_path
    pedidos = nil
    Zip::InputStream.open(StringIO.new(response.body)) do |zip|
      while (entry = zip.get_next_entry)
        pedidos = JSON.parse(zip.read) if entry.name == "pedidos.json"
      end
    end
    expect(pedidos.first).to include("codigo" => order.code, "situacao" => "concluído", "desfecho" => "parcial", "total" => "R$ 35,00")
    expect(pedidos.first["itens"].first["produto"]).to eq("Bolo de fubá")
  end
end
