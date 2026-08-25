require "rails_helper"

RSpec.describe "Vitrine pública" do
  let!(:enterprise) do
    e = create_enterprise(name: "Doces da Cida", whatsapp: "13 99999-0001", short_description: "Doces caseiros")
    e.update!(content: { "blocks" => [ { "type" => "paragraph", "data" => { "text" => "Fazemos doces desde 1998." } } ] })
    publish(e)
  end

  it "responde no endereço curto com o conteúdo renderizado e o WhatsApp" do
    get "/doces-da-cida"
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("<p>Fazemos doces desde 1998.</p>", "Doces caseiros", "wa.me/5513999990001")
  end

  it "não mostra rascunho" do
    enterprise.unpublish!
    get "/doces-da-cida"
    expect(response).to have_http_status(:not_found)
  end

  it "leva de volta ao hub com a busca aberta quando o endereço não existe" do
    get "/doces-da-cidda"
    expect(response).to have_http_status(:not_found)
    expect(response.body).to include("Não achamos «doces-da-cidda»", "autofocus")
  end

  it "é leve: HTML + CSS + JS abaixo de 100 KB comprimidos, sem imagens (≈ 2 s em 3G)" do
    get "/doces-da-cida"
    html = response.body
    assets = html.scan(/(?:href|src)="(\/assets\/[^"]+)"/).flatten.uniq
    expect(assets.grep(%r{@editorjs|/assets/editor-})).to be_empty, "a vitrine não deve carregar o editor"
    total = Zlib.gzip(html).bytesize
    assets.each do |path|
      get path
      total += Zlib.gzip(response.body).bytesize
    end
    expect(total).to be < 100.kilobytes, "peso total comprimido: #{total / 1024} KB"
  end

  it "conta a visita na telemetria própria" do
    get "/doces-da-cida", headers: { "User-Agent" => "Mozilla/5.0 (Linux; Android 10)" }
    expect(PageView.find_by(path: "/doces-da-cida").count).to eq(1)
  end
end
