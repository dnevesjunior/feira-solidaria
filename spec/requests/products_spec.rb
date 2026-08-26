require "rails_helper"

RSpec.describe "Produtos" do
  let(:maria) { create_user(name: "Maria", phone: "13 90000-0001") }
  let!(:loja) { publish(create_enterprise(user: maria, name: "Doces da Cida", whatsapp: "13 99999-0001")) }

  describe "cadastro pelo celular (Epic 2: mínimo nome, preço, foto)" do
    it "o formulário tem exatamente dois campos obrigatórios; foto só para publicar" do
      sign_in_as maria
      get new_my_enterprise_product_path
      required = response.body.scan(/<(input|select|textarea)[^>]*\brequired\b[^>]*>/).size
      expect(required).to eq(2)
      expect(response.body).to include('name="product[name]"', 'name="product[price_input]"')
    end

    it "cadastra três produtos com foto e publica" do
      sign_in_as maria
      3.times do |i|
        post my_enterprise_products_path, params: { product: { name: "Produto #{i}", price_input: "1#{i},50", sale_unit: "unidade", photos: [ jpeg_upload ] } }
        expect(response).to redirect_to(my_enterprise_products_path)
      end
      expect(loja.products.count).to eq(3)
      expect(loja.products.first.price).to eq(Amount.brl(1050))
      product = loja.products.first
      post publish_my_enterprise_product_path(product)
      expect(product.reload).to be_published
    end

    it "aceita unidade de venda própria" do
      sign_in_as maria
      post my_enterprise_products_path, params: { product: { name: "Banana", price_input: "5", sale_unit: "outra", sale_unit_other: "cacho" } }
      expect(loja.products.last.sale_unit).to eq("cacho")
    end

    it "explica o formato do preço quando vem errado" do
      sign_in_as maria
      post my_enterprise_products_path, params: { product: { name: "Bolo", price_input: "12.50" } }
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("12,50")
    end

    it "não publica sem foto e diz por quê" do
      sign_in_as maria
      post my_enterprise_products_path, params: { product: { name: "Bolo", price_input: "12" } }
      product = loja.products.last
      post publish_my_enterprise_product_path(product)
      follow_redirect!
      expect(response.body).to include("pelo menos uma")
      expect(product.reload).to be_draft
    end
  end

  describe "pausar e despausar" do
    let!(:bolo) { create_product(loja, name: "Bolo de fubá") }

    it "some da vitrine e do catálogo em pausa, e volta ao despausar" do
      get "/doces-da-cida"
      expect(response.body).to include("Bolo de fubá", "R$ 25,00")
      get catalog_path
      expect(response.body).to include("Bolo de fubá")

      sign_in_as maria
      post pause_my_enterprise_product_path(bolo)
      get "/doces-da-cida"
      expect(response.body).not_to include("Bolo de fubá")
      get catalog_path
      expect(response.body).not_to include("Bolo de fubá")

      post unpause_my_enterprise_product_path(bolo)
      get "/doces-da-cida"
      expect(response.body).to include("Bolo de fubá")
    end
  end

  describe "catálogo" do
    before do
      create_product(loja, name: "Bolo de fubá")
      outra = publish(create_enterprise(name: "Pães da Rosângela", whatsapp: "13 99999-0002"))
      create_product(outra, name: "Broa")
    end

    it "lista produtos com link para a loja, semente do dia, sem ranking" do
      get catalog_path
      expect(response.body).to include("Bolo de fubá", "Broa", Date.current.iso8601)
      expect(response.body).to include('href="/doces-da-cida#produto-')
      expect(response.body).not_to match(/mais vendidos|em alta|recomendad/i)
    end

    it "busca por nome" do
      get catalog_path, params: { q: "broa" }
      expect(response.body).to include("Broa")
      expect(response.body).not_to include("Bolo de fubá")
    end

    it "não mostra filtro de categoria enquanto a feira não definir categorias" do
      get catalog_path
      expect(response.body).not_to include('class="filtros"')
    end
  end

  describe "capacidade da rede" do
    before do
      create_product(loja, name: "Pão de queijo", capacity_quantity: 10, capacity_period: "week")
      outra = publish(create_enterprise(name: "Pães da Rosângela", whatsapp: "13 99999-0002"))
      create_product(outra, name: "Pão de Queijo", capacity_quantity: 2, capacity_period: "day")
    end

    it "qualquer membro vê a soma semanal; visitante não" do
      get network_capacity_path
      expect(response).to redirect_to(new_session_path)

      sign_in_as maria
      get network_capacity_path
      expect(response.body).to include("Capacidade da rede", "aproximadas")
      expect(response.body).to match(%r{<td>Pão de [Qq]ueijo</td><td>24</td><td>2</td>})
      expect(response.body).to include("<th>24</th>")
    end

    it "não aparece na vitrine pública" do
      get "/doces-da-cida"
      expect(response.body).not_to match(/capacidade|por semana/i)
    end
  end

  it "escopo: membro de A não edita nem pausa produto de B" do
    jose = create_user(name: "José", phone: "13 90000-0002")
    loja_b = publish(create_enterprise(user: jose, name: "Loja B", whatsapp: "13 99999-0009"))
    produto_b = create_product(loja_b, name: "Sabão")
    sign_in_as maria
    get edit_my_enterprise_product_path(produto_b)
    expect(response).to have_http_status(:not_found)
    post pause_my_enterprise_product_path(produto_b)
    expect(response).to have_http_status(:not_found)
    expect(produto_b.reload).to be_published
  end

  it "export inclui produtos com histórico de capacidade e fotos" do
    sign_in_as maria
    bolo = create_product(loja, name: "Bolo de fubá", capacity_quantity: 5, capacity_period: "week")
    bolo.update!(capacity_quantity: 8)
    get my_enterprise_export_path
    names = []
    produtos = nil
    Zip::InputStream.open(StringIO.new(response.body)) do |zip|
      while (entry = zip.get_next_entry)
        names << entry.name
        produtos = JSON.parse(zip.read) if entry.name == "produtos.json"
      end
    end
    expect(names).to include("produtos.json", "imagens/produto-#{bolo.id}-1.jpg")
    expect(produtos.first["preco"]).to eq("R$ 25,00")
    expect(produtos.first["preco_centavos"]).to eq(2500)
    expect(produtos.first["historico_de_capacidade"].last["para"]["quantidade"]).to eq(8)
  end
end
