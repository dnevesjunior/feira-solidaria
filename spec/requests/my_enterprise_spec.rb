require "rails_helper"

RSpec.describe "Minha loja" do
  let(:maria) { create_user(name: "Maria", phone: "13 90000-0001") }
  let!(:jose) { create_user(name: "José", phone: "13 90000-0002") }

  it "cria o empreendimento em rascunho e leva para a edição" do
    sign_in_as maria
    post my_enterprise_create_path, params: { enterprise: { name: "Doces da Cida", whatsapp: "(13) 99999-0001" } }
    expect(response).to redirect_to(my_enterprise_edit_path)
    e = Enterprise.last
    expect(e).to be_draft
    expect(e.users).to eq([ maria ])
    expect(e.slug).to eq("doces-da-cida")
  end

  it "recusa conteúdo com script e não grava nada" do
    sign_in_as maria
    e = create_enterprise(user: maria)
    patch my_enterprise_update_path, params: { enterprise: { name: e.name, whatsapp: e.whatsapp,
      content: { blocks: [ { type: "paragraph", data: { text: "<script>alert(1)</script>" } } ] }.to_json } }
    expect(response).to have_http_status(:unprocessable_entity)
    expect(e.reload.content["blocks"]).to eq([])
    expect(response.body).to include("código que não é permitido")
  end

  it "salva conteúdo válido, mostra prévia e publica" do
    sign_in_as maria
    e = create_enterprise(user: maria)
    patch my_enterprise_update_path, params: { enterprise: { name: e.name, whatsapp: e.whatsapp,
      content: { blocks: [ { type: "header", data: { text: "Quem somos", level: 2 } }, { type: "paragraph", data: { text: "Olá" } } ] }.to_json } }
    expect(response).to redirect_to(my_enterprise_path)

    get my_enterprise_preview_path
    expect(response.body).to include("Prévia", "<h2>Quem somos</h2>")
    get "/#{e.slug}"
    expect(response).to have_http_status(:not_found)

    post my_enterprise_publish_path
    expect(e.reload).to be_published
    get "/#{e.slug}"
    expect(response).to have_http_status(:ok)
  end

  it "mostra as visitas só da própria loja" do
    sign_in_as maria
    e = publish(create_enterprise(user: maria))
    3.times { PageView.count!("/#{e.slug}") }
    9.times { PageView.count!("/outra") }
    get my_enterprise_path
    expect(response.body).to include("vista <strong>3</strong> vezes")
    expect(response.body).not_to include("<strong>9</strong>")
  end

  describe "escopo por empreendimento (CLAUDE.md §3.5)" do
    let!(:loja_a) { create_enterprise(user: maria, name: "Loja A", whatsapp: "13 99999-0001") }
    let!(:loja_b) { create_enterprise(user: jose, name: "Loja B", whatsapp: "13 99999-0002") }

    it "membro de A não edita B mesmo forçando a sessão" do
      sign_in_as maria
      get my_enterprise_edit_path
      expect(response.body).to include("Loja A")
      # Tenta apontar a sessão para B: a validação contra as memberships ignora.
      allow_any_instance_of(ActionDispatch::Request::Session).to receive(:[]).and_call_original
      allow_any_instance_of(ActionDispatch::Request::Session).to receive(:[]).with(:enterprise_id).and_return(loja_b.id)
      get my_enterprise_edit_path
      expect(response.body).not_to include("Loja B")
    end

    it "upload de A não renderiza em B" do
      image_a = attach_content_image(loja_a)
      sign_in_as jose
      patch my_enterprise_update_path, params: { enterprise: { name: loja_b.name, whatsapp: loja_b.whatsapp,
        content: { blocks: [ { type: "image", data: { file: { signed_id: image_a.signed_id_for_document } } } ] }.to_json } }
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("não pertence a este empreendimento")
    end

    it "ContentImage.for_current só vê o próprio empreendimento" do
      attach_content_image(loja_a)
      attach_content_image(loja_b)
      Current.enterprise = loja_a
      expect(ContentImage.for_current.count).to eq(1)
      expect(ContentImage.for_current.first.enterprise).to eq(loja_a)
    end
  end

  it "adiciona e remove pessoas pelo telefone" do
    sign_in_as maria
    e = create_enterprise(user: maria)
    post my_enterprise_memberships_path, params: { phone: "(13) 90000-0002" }
    expect(e.users.reload).to include(jose)
    post my_enterprise_memberships_path, params: { phone: "13 90000-0099" }
    follow_redirect!
    expect(response.body).to include("Não achamos ninguém")
    delete my_enterprise_membership_path(e.memberships.find_by(user: jose))
    expect(e.users.reload).not_to include(jose)
  end

  it "exporta um zip com dados, vitrine, eventos e imagens" do
    sign_in_as maria
    e = create_enterprise(user: maria)
    e.cover_image.attach(jpeg_upload)
    e.save!
    image = attach_content_image(e)
    e.update!(content: { "blocks" => [ { "type" => "image", "data" => { "file" => { "signed_id" => image.signed_id_for_document } } } ] })

    get my_enterprise_export_path
    expect(response.media_type).to eq("application/zip")
    names = []
    Zip::InputStream.open(StringIO.new(response.body)) do |zip|
      while (entry = zip.get_next_entry)
        names << entry.name
        if entry.name == "empreendimento.json"
          data = JSON.parse(zip.read)
          expect(data["nome"]).to eq("Doces da Cida")
          expect(data["membros"].first["nome"]).to eq("Maria")
        end
      end
    end
    expect(names).to include("LEIA-ME.txt", "empreendimento.json", "vitrine.json", "eventos.json", "imagens/capa.jpg", "imagens/conteudo-#{image.id}.jpg")
    expect(Event.where(kind: "enterprise.exported", subject: e)).to exist
  end

  it "recebe upload do editor e responde no formato do EditorJS" do
    sign_in_as maria
    e = create_enterprise(user: maria)
    post my_enterprise_content_images_path, params: { image: jpeg_upload(width: 800, height: 600) }
    expect(response).to have_http_status(:ok)
    body = JSON.parse(response.body)
    expect(body["success"]).to eq(1)
    expect(body["file"]["signed_id"]).to be_present
    expect(body["file"]["url"]).to include("/rails/active_storage/representations/proxy/")
    expect(e.content_images.count).to eq(1)

    post my_enterprise_content_images_path, params: { image: Rack::Test::UploadedFile.new(StringIO.new("x"), "text/plain", original_filename: "x.txt") }
    expect(response).to have_http_status(:unprocessable_entity)
    expect(JSON.parse(response.body)["message"]).to include("JPG")
  end
end
