# frozen_string_literal: true

# Log de eventos append-only (ADR 0006, CLAUDE.md §3.3).
#
#   Event.record("enterprise.published", subject: enterprise, actor: Current.user)
#
# Regras:
# - Cria-se, nunca se altera nem se apaga. O ActiveRecord recusa (readonly?) e
#   o banco recusa (trigger events_append_only).
# - Todo `kind` está registrado em Event::Catalog, com as chaves de payload
#   permitidas. Chave fora da lista invalida o evento.
# - O payload NUNCA contém dado pessoal — nem de comprador, nem de membro.
#   Só referências (ids) e valores de domínio. É o que torna o expurgo de dados
#   de comprador (Epic 3.9) compatível com a imutabilidade.
class Event < ApplicationRecord
  belongs_to :actor, polymorphic: true, optional: true
  belongs_to :subject, polymorphic: true, optional: true

  validates :kind, :occurred_at, presence: true
  validate :kind_is_in_catalog
  validate :payload_keys_are_allowed

  def self.record(kind, subject: nil, actor: nil, payload: {}, occurred_at: Time.current)
    create!(kind: kind.to_s, subject:, actor:, payload: payload.to_h.deep_stringify_keys, occurred_at:)
  end

  def readonly? = persisted?

  def catalog_entry = Event::Catalog[kind]

  private

  def kind_is_in_catalog
    return if kind.blank? || Event::Catalog.include?(kind)
    errors.add(:kind, "não está registrado em Event::Catalog: #{kind}")
  end

  def payload_keys_are_allowed
    entry = catalog_entry or return
    extra = payload.keys.map(&:to_s) - entry.payload_keys
    return if extra.empty?
    errors.add(:payload, "chaves não permitidas para #{kind}: #{extra.join(', ')}")
  end
end
