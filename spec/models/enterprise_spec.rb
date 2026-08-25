require "rails_helper"

RSpec.describe Enterprise do
  let(:user) { create_user }

  it "nasce em rascunho com slug gerado do nome" do
    e = create_enterprise(user:)
    expect(e).to be_draft
    expect(e.slug).to eq("doces-da-cida")
    expect(Event.where(kind: "enterprise.created", subject: e)).to exist
  end

  it "normaliza WhatsApp e Instagram" do
    e = create_enterprise(user:, whatsapp: "(13) 99999-0001", instagram: "https://instagram.com/doces.da.cida/")
    expect(e.whatsapp).to eq("+5513999990001")
    expect(e.instagram).to eq("doces.da.cida")
  end

  it "exige WhatsApp válido" do
    e = Enterprise.new(name: "Loja", whatsapp: "123")
    expect(e).not_to be_valid
    expect(e.errors[:whatsapp]).to be_present
  end

  it "publica e despublica registrando eventos" do
    e = create_enterprise(user:)
    e.publish!
    expect(e.reload).to be_published
    expect(e.published_at).to be_present
    e.unpublish!
    expect(e.reload).to be_draft
    expect(Event.where(subject: e).pluck(:kind)).to include("enterprise.published", "enterprise.unpublished")
  end

  it "permite editar o slug em rascunho e não depois de publicado" do
    e = create_enterprise(user:)
    expect(e.update(slug: "cida")).to be(true)
    e.publish!
    expect(e.update(slug: "outra")).to be(false)
    expect(e.errors[:slug].join).to match(/publicada/)
  end

  it "recusa slug reservado ou fora do formato" do
    e = create_enterprise(user:)
    expect(e.update(slug: "minha-loja")).to be(false)
    expect(e.update(slug: "Doces 1")).to be(false)
  end

  it "registra enterprise.updated só com nomes de campos, nunca valores" do
    e = create_enterprise(user:)
    e.update!(short_description: "Doces caseiros", neighborhood: "Vila Gilda")
    event = Event.where(kind: "enterprise.updated", subject: e).last
    expect(event.payload).to eq({ "changed" => %w[neighborhood short_description] })
    expect(event.payload.to_s).not_to include("Vila Gilda")
  end

  it "recusa conteúdo com script" do
    e = create_enterprise(user:)
    e.content = { "blocks" => [ { "type" => "paragraph", "data" => { "text" => "oi <script>alert(1)</script>" } } ] }
    expect(e).not_to be_valid
    expect(e.errors[:content].join).to match(/código/)
  end

  it "recusa foto que não é imagem e aceita JPEG" do
    e = create_enterprise(user:)
    e.cover_image.attach(io: StringIO.new("%PDF-1.4"), filename: "doc.pdf", content_type: "application/pdf")
    expect(e).not_to be_valid
    expect(e.errors[:cover_image].join).to match(/JPG/)

    e = create_enterprise(user:, name: "Outra loja", whatsapp: "13 99999-0002")
    e.cover_image.attach(jpeg_upload)
    expect(e).to be_valid
  end

  it "conta visitas só da própria vitrine" do
    e = create_enterprise(user:)
    PageView.count!("/#{e.slug}")
    PageView.count!("/#{e.slug}")
    PageView.count!("/outra-loja")
    expect(e.page_views_last_30_days).to eq(2)
  end
end
