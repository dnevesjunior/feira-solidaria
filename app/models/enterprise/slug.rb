# frozen_string_literal: true

# Endereço falável da vitrine (Epic 1, nota de desenho): vai ser dito em voz
# alta, escrito em papel e digitado no ponto de ônibus. Curto, sem acento, sem
# hífen duplo, sem número.
module Enterprise::Slug
  MAX_LENGTH = 30
  FORMAT = /\A[a-z]+(?:-[a-z]+)*\z/
  # Caminhos da própria aplicação e nomes que confundiriam.
  RESERVED = %w[
    entrar sair minha-conta minha-loja proxima-feira feira up rails assets
    admin api login logout cadastro ajuda sobre contato
  ].freeze

  def self.generate(name, taken: ->(_) { false })
    base = ActiveSupport::Inflector.transliterate(name.to_s).downcase
      .gsub(/[^a-z\s-]/, " ")     # remove dígitos e símbolos
      .strip.gsub(/[\s-]+/, "-")
    base = base[0, MAX_LENGTH].sub(/-[^-]*\z/, "") if base.length > MAX_LENGTH
    base = "loja" if base.blank? || reserved?(base)

    candidate = base
    suffixes = %w[da-feira solidaria nova outra]
    i = 0
    while taken.call(candidate)
      suffix = suffixes[i] || "#{suffixes.last}-#{i - suffixes.size + 2}"
      candidate = "#{base[0, MAX_LENGTH - suffix.length - 1]}-#{suffix}".gsub(/-+/, "-")
      i += 1
    end
    candidate
  end

  def self.valid?(slug) = slug.to_s.match?(FORMAT) && slug.length <= MAX_LENGTH
  def self.reserved?(slug) = RESERVED.include?(slug.to_s)
end
