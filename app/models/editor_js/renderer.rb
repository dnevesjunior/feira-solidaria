# frozen_string_literal: true

# HTML a partir de um EditorJs::Document válido (ADR 0009). Texto inline passa
# pelo sanitizador com allowlist mínima; imagens saem com dimensões e lazy.
class EditorJs::Renderer
  include ActionView::Helpers::TagHelper
  include ActionView::Helpers::SanitizeHelper
  include Rails.application.routes.url_helpers

  INLINE_TAGS = %w[b i strong em a br].freeze
  INLINE_ATTRS = %w[href].freeze

  def initialize(document)
    @document = document
  end

  def to_html
    raise ArgumentError, "documento inválido: #{@document.errors.join('; ')}" unless @document.valid?
    safe_join(@document.blocks.map { |block| render_block(block) }, "\n")
  end

  private

  def render_block(block)
    data = block["data"]
    case block["type"]
    when "paragraph" then tag.p(inline(data["text"]))
    when "header" then content_tag(:"h#{data['level']}", inline(data["text"]))
    when "quote"
      tag.blockquote do
        safe_join([ tag.p(inline(data["text"])), (tag.cite(inline(data["caption"])) if data["caption"].present?) ].compact)
      end
    when "list" then render_list(data["items"], data["style"])
    when "image" then render_image(data)
    end
  end

  def render_list(items, style)
    content_tag(style == "ordered" ? :ol : :ul) do
      safe_join(items.map do |item|
        tag.li { safe_join([ inline(item["content"]), (render_list(item["items"], style) if item["items"].present?) ].compact) }
      end)
    end
  end

  def render_image(data)
    image = @document.image_blobs[data.dig("file", "signed_id")] or return nil
    variant = image.file.variant(:content)
    # Caminho (sem host) da variante pelo proxy — o helper `direct` do Active
    # Storage exige host; o nomeado não.
    src = rails_blob_representation_proxy_path(variant.blob.signed_id, variant.variation.key, variant.blob.filename)
    tag.figure do
      safe_join([
        tag.img(src:,
                alt: strip_tags(data["caption"].to_s), loading: "lazy",
                width: image.width, height: image.height),
        (tag.figcaption(inline(data["caption"])) if data["caption"].present?)
      ].compact)
    end
  end

  def inline(text)
    sanitize(text.to_s, tags: INLINE_TAGS, attributes: INLINE_ATTRS)
  end
end
