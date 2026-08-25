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
end
