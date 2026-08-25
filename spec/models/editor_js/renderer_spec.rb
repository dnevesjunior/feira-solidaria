require "rails_helper"

RSpec.describe EditorJs::Renderer do
  let(:enterprise) { create_enterprise }

  def html(blocks) = described_class.new(EditorJs::Document.new({ "blocks" => blocks }, enterprise:)).to_html

  it "renderiza parágrafo, título, lista e citação com inline sanitizado" do
    out = html([
      { "type" => "header", "data" => { "text" => "Quem <i>somos</i>", "level" => 3 } },
      { "type" => "paragraph", "data" => { "text" => "Veja <a href=\"https://exemplo.org\" target=\"_blank\">aqui</a> <u>x</u>" } },
      { "type" => "list", "data" => { "style" => "ordered", "items" => [ { "content" => "Um", "items" => [ { "content" => "Sub", "items" => [] } ] } ] } },
      { "type" => "quote", "data" => { "text" => "Feito à mão", "caption" => "Cida" } }
    ])
    expect(out).to include("<h3>Quem <i>somos</i></h3>")
    expect(out).to include('<a href="https://exemplo.org">aqui</a>')
    expect(out).not_to include("target=")
    expect(out).not_to include("<u>")
    expect(out).to include("<ol><li>Um<ol><li>Sub</li></ol></li></ol>")
    expect(out).to include("<blockquote><p>Feito à mão</p><cite>Cida</cite></blockquote>")
  end

  it "renderiza imagem do próprio empreendimento com lazy e dimensões" do
    image = attach_content_image(enterprise, width: 800, height: 600)
    out = html([ { "type" => "image", "data" => { "file" => { "signed_id" => image.signed_id_for_document }, "caption" => "Bolo" } } ])
    expect(out).to include('loading="lazy"')
    expect(out).to include('width="800"')
    expect(out).to include("<figcaption>Bolo</figcaption>")
    expect(out).to include("/rails/active_storage/representations/proxy/")
  end

  it "recusa renderizar documento inválido" do
    expect { html([ { "type" => "raw", "data" => {} } ]) }.to raise_error(ArgumentError)
  end
end
