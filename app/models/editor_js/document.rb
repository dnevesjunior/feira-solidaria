# frozen_string_literal: true

# Documento EditorJS validado por allowlist (ADR 0009; CLAUDE.md §5).
#
# Persistimos o JSON, nunca HTML. Bloco fora da lista, título fora de h2/h3,
# imagem de outro empreendimento ou texto com script/handler/javascript: →
# documento INVÁLIDO. Rejeitar é melhor do que limpar em silêncio: a pessoa
# vê o erro e o conteúdo perigoso nunca é gravado.
class EditorJs::Document
  BLOCKS = %w[paragraph header list quote image].freeze
  HEADER_LEVELS = [ 2, 3 ].freeze
  LIST_STYLES = %w[ordered unordered].freeze
  MAX_BLOCKS = 60
  MAX_TEXT = 4_000
  DANGEROUS = /<\s*(script|iframe|object|embed|style|form|svg)|\bon\w+\s*=|javascript:|data:text\/html/i

  attr_reader :blocks, :errors

  def initialize(raw, enterprise: nil)
    @enterprise = enterprise
    @errors = []
    @blocks = []
    parse(raw)
  end

  def valid? = errors.empty?
  def empty? = blocks.empty?

  def to_h = { "blocks" => blocks }

  # Blobs de imagem referenciados, já verificados como do próprio empreendimento.
  def image_blobs = @image_blobs ||= {}

  private

  def parse(raw)
    data = raw.is_a?(String) ? JSON.parse(raw) : raw.to_h
    list = data["blocks"] || data[:blocks]
    return @errors << "está num formato que não reconhecemos" unless list.is_a?(Array)
    return @errors << "tem blocos demais (máximo #{MAX_BLOCKS})" if list.size > MAX_BLOCKS

    @blocks = list.map { |block| validate_block(block.to_h.deep_stringify_keys) }.compact
  rescue JSON::ParserError
    @errors << "está num formato que não reconhecemos"
  end

  def validate_block(block)
    type = block["type"].to_s
    data = block["data"].is_a?(Hash) ? block["data"] : {}
    unless BLOCKS.include?(type)
      @errors << "contém um tipo de bloco não permitido: #{type.presence || 'desconhecido'}"
      return nil
    end
    send(:"validate_#{type}", data)
  end

  def validate_paragraph(data)
    text = safe_text(data["text"]) or return nil
    { "type" => "paragraph", "data" => { "text" => text } }
  end

  def validate_header(data)
    text = safe_text(data["text"]) or return nil
    level = data["level"].to_i
    level = 2 unless HEADER_LEVELS.include?(level)
    { "type" => "header", "data" => { "text" => text, "level" => level } }
  end

  def validate_quote(data)
    text = safe_text(data["text"]) or return nil
    caption = data["caption"].present? ? safe_text(data["caption"]) : ""
    return nil if caption.nil?
    { "type" => "quote", "data" => { "text" => text, "caption" => caption } }
  end

  def validate_list(data)
    style = LIST_STYLES.include?(data["style"]) ? data["style"] : "unordered"
    items = validate_list_items(data["items"], depth: 0) or return nil
    { "type" => "list", "data" => { "style" => style, "items" => items } }
  end

  def validate_list_items(items, depth:)
    return [] unless items.is_a?(Array)
    return @errors << "tem listas aninhadas demais" && nil if depth > 2
    items.first(50).map do |item|
      item = { "content" => item } if item.is_a?(String) # formato antigo (1.x)
      content = safe_text(item["content"]) or return nil
      nested = validate_list_items(item["items"], depth: depth + 1) or return nil
      { "content" => content, "items" => nested }
    end
  end

  def validate_image(data)
    signed_id = data.dig("file", "signed_id").to_s
    image = signed_id.present? && @enterprise && @enterprise.content_images.find_by_signed_id(signed_id)
    unless image
      @errors << "contém uma imagem que não pertence a este empreendimento"
      return nil
    end
    caption = data["caption"].present? ? safe_text(data["caption"]) : ""
    return nil if caption.nil?
    image_blobs[signed_id] = image
    { "type" => "image", "data" => { "file" => { "signed_id" => signed_id }, "caption" => caption } }
  end

  def safe_text(value)
    text = value.to_s
    if text.length > MAX_TEXT
      @errors << "tem um trecho de texto longo demais"
      return nil
    end
    if text.match?(DANGEROUS)
      @errors << "contém código que não é permitido"
      return nil
    end
    text
  end
end
