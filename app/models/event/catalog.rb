# frozen_string_literal: true

# Dicionário dos tipos de evento (ADR 0006). Cada epic registra os seus aqui
# antes de emiti-los. `payload_keys` é allowlist: o que não está listado não
# entra — e dado pessoal nunca está listado.
module Event::Catalog
  Entry = Data.define(:kind, :description, :payload_keys)

  @registry = {}

  class << self
    def register(kind, description:, payload_keys: [])
      @registry[kind.to_s] = Entry.new(kind: kind.to_s, description:, payload_keys: payload_keys.map(&:to_s).freeze)
    end

    def [](kind) = @registry[kind.to_s]
    def include?(kind) = @registry.key?(kind.to_s)
    def kinds = @registry.keys
    def entries = @registry.values
  end

  # --- Epic 0 ---------------------------------------------------------------
  register "user.created",
    description: "Conta de membro criada (por tarefa da coordenação ou seed). O nome fica no registro da conta, não aqui."
  register "user.password_reset_by_coordination",
    description: "Senha redefinida pela coordenação, presencialmente. Registrado para que esse poder seja observável (ADR 0007)."

  # --- Epic 1 ---------------------------------------------------------------
  register "enterprise.created", description: "Empreendimento criado (em rascunho)."
  register "enterprise.updated", description: "Dados ou conteúdo da vitrine alterados. Só os nomes dos campos, nunca os valores.",
    payload_keys: %w[changed]
  register "enterprise.published", description: "Vitrine publicada — ato deliberado do empreendimento."
  register "enterprise.unpublished", description: "Vitrine despublicada; volta a rascunho."
  register "enterprise.member_added", description: "Pessoa adicionada ao empreendimento.", payload_keys: %w[user_id]
  register "enterprise.member_removed", description: "Pessoa removida do empreendimento.", payload_keys: %w[user_id]
  register "enterprise.exported", description: "O empreendimento exportou seus próprios dados (CLAUDE.md §3.3)."
  register "content_image.created", description: "Foto enviada para o conteúdo da vitrine.", payload_keys: %w[content_image_id]
  register "content_image.removed", description: "Foto removida do conteúdo da vitrine.", payload_keys: %w[content_image_id]
  register "fair_event.created", description: "Próxima feira cadastrada (data e local)."
  register "fair_event.updated", description: "Próxima feira alterada."
end
