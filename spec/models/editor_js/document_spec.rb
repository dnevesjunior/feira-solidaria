require "rails_helper"

RSpec.describe EditorJs::Document do
  let(:enterprise) { create_enterprise }

  def doc(blocks) = described_class.new({ "blocks" => blocks }, enterprise:)

  it "aceita os blocos da allowlist" do
    d = doc([
      { "type" => "header", "data" => { "text" => "Quem somos", "level" => 2 } },
      { "type" => "paragraph", "data" => { "text" => "Fazemos <b>doces</b> caseiros." } },
      { "type" => "list", "data" => { "style" => "unordered", "items" => [ { "content" => "Bolo", "items" => [] }, "Brigadeiro" ] } },
      { "type" => "quote", "data" => { "text" => "Feito com carinho", "caption" => "Cida" } }
    ])
    expect(d).to be_valid
    expect(d.blocks.size).to eq(4)
  end

  it "rejeita bloco fora da allowlist" do
    d = doc([ { "type" => "raw", "data" => { "html" => "<div>x</div>" } } ])
    expect(d).not_to be_valid
    expect(d.errors.join).to match(/não permitido: raw/)
  end

  it "rejeita script, handlers e javascript:" do
    [
      "<script>alert(1)</script>",
      "<img src=x onerror=alert(1)>",
      "<a href=\"javascript:alert(1)\">x</a>",
      "<iframe src=//x></iframe>"
    ].each do |text|
      d = doc([ { "type" => "paragraph", "data" => { "text" => text } } ])
      expect(d).not_to be_valid, "deveria rejeitar: #{text}"
    end
  end

  it "limita títulos a h2/h3" do
    d = doc([ { "type" => "header", "data" => { "text" => "T", "level" => 1 } } ])
    expect(d.blocks.first["data"]["level"]).to eq(2)
  end

  it "só aceita imagens do próprio empreendimento" do
    mine = attach_content_image(enterprise)
    other = attach_content_image(create_enterprise(name: "Outra", whatsapp: "13 99999-0009"))

    ok = doc([ { "type" => "image", "data" => { "file" => { "signed_id" => mine.signed_id_for_document }, "caption" => "" } } ])
    expect(ok).to be_valid

    leak = doc([ { "type" => "image", "data" => { "file" => { "signed_id" => other.signed_id_for_document } } } ])
    expect(leak).not_to be_valid
    expect(leak.errors.join).to match(/não pertence/)

    forged = doc([ { "type" => "image", "data" => { "file" => { "signed_id" => "abc" } } } ])
    expect(forged).not_to be_valid
  end

  it "rejeita formato desconhecido" do
    expect(described_class.new("nao é json", enterprise:)).not_to be_valid
    expect(described_class.new({ "blocks" => "x" }, enterprise:)).not_to be_valid
  end
end
