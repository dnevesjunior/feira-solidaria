# frozen_string_literal: true

# Produto de um empreendimento, com capacidade declarada (Epic 2). Escopado
# (ADR 0005). Preço em centavos (ADR 0004). Sem estoque: "pausado" é "não
# estou produzindo isso agora", que é a situação real de quem parou por
# doença, viagem, falta de insumo ou estação.
class Product < ApplicationRecord
  include EnterpriseScoped

  STATUSES = %w[draft published paused].freeze
  SALE_UNITS = [ "unidade", "par", "dúzia", "kg", "500 g", "100 g", "pote", "litro", "pacote", "metro", "fatia" ].freeze
  MAX_PHOTOS = 4

  # A coluna bigint é lida e escrita como Amount em reais (ADR 0004): nunca um
  # inteiro solto, nunca float. `price` é o nome de domínio; a coluna carrega a
  # unidade no nome.
  attribute :price_cents, :amount, unit: :brl
  def price = price_cents

  belongs_to :category, optional: true

  has_many_attached :photos do |attachable|
    attachable.variant :thumb, resize_to_fill: [ 320, 320 ], **ImageVariants::JPEG, preprocessed: true
    attachable.variant :content, resize_to_limit: ImageVariants::CONTENT_LIMIT, **ImageVariants::JPEG, preprocessed: true
  end

  normalizes :name, :sale_unit, with: ->(raw) { raw.to_s.squish.presence }
  normalizes :description, with: ->(raw) { raw.to_s.strip.presence }

  validates :name, presence: true, length: { in: 2..80 }
  validates :description, length: { maximum: 1000 }, allow_nil: true
  validate :price_is_positive
  validates :sale_unit, presence: true, length: { maximum: 20 }
  validates :status, inclusion: { in: STATUSES }
  validates :capacity_period, inclusion: { in: Product::Capacity::PERIODS }
  validates :capacity_quantity, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
  validates :lead_time_days, numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than: 366 }, allow_nil: true
  validates :photos, image_uploads: { max: MAX_PHOTOS }
  validate :photo_required_when_visible

  after_create { Event.record("product.created", subject: self, actor: Current.user) }
  after_update :record_capacity_change
  after_update :record_updated_event
  after_destroy { Event.record("product.removed", subject: enterprise, actor: Current.user, payload: { product_id: id }) }

  scope :published, -> { where(status: "published") }
  scope :visible, -> { published }
  scope :by_name, -> { order(:name) }

  def draft? = status == "draft"
  def published? = status == "published"
  def paused? = status == "paused"

  def price=(amount)
    raise ArgumentError, "preço precisa ser Amount em reais" unless amount.nil? || (amount.is_a?(Amount) && amount.brl?)
    self.price_cents = amount
  end

  # Aceita "12,50" (pt-BR) ou Amount.
  def price_input=(raw)
    amount = raw.is_a?(Amount) ? raw : Amount.parse_brl(raw)
    @price_input_invalid = amount.nil? && raw.present?
    self.price = amount
  end

  def price_input = price&.to_s&.delete_prefix("R$ ")

  def publish!
    transaction do
      update!(status: "published")
      Event.record("product.published", subject: self, actor: Current.user)
    end
  end

  def pause!
    transaction do
      update!(status: "paused")
      Event.record("product.paused", subject: self, actor: Current.user)
    end
  end

  def unpause!
    transaction do
      update!(status: "published")
      Event.record("product.unpaused", subject: self, actor: Current.user)
    end
  end

  def weekly_capacity = Product::Capacity.weekly(capacity_quantity, capacity_period)
  def capacity_label = capacity_quantity && "#{capacity_quantity} #{sale_unit} #{Product::Capacity.label(capacity_period)}"

  # Histórico da própria declaração — a pessoa vê o que declarou ao longo do
  # tempo, e ele vai no export.
  def capacity_history
    Event.where(kind: "product.capacity_changed", subject: self).order(:id)
  end

  private

  def price_is_positive
    return if price&.positive? && !@price_input_invalid
    errors.add(:price_cents, "precisa ser um valor como 12,50")
  end

  def photo_required_when_visible
    return if draft? || photos.attached?
    errors.add(:photos, "são necessárias para publicar: envie pelo menos uma")
  end

  def record_capacity_change
    return unless saved_change_to_capacity_quantity? || saved_change_to_capacity_period?
    from_q, to_q = saved_change_to_capacity_quantity? ? saved_change_to_capacity_quantity : [ capacity_quantity ] * 2
    from_p, to_p = saved_change_to_capacity_period? ? saved_change_to_capacity_period : [ capacity_period ] * 2
    Event.record("product.capacity_changed", subject: self, actor: Current.user,
      payload: { quantity_from: from_q, quantity_to: to_q, period_from: from_p, period_to: to_p })
  end

  def record_updated_event
    changed = saved_changes.keys - %w[updated_at status capacity_quantity capacity_period]
    return if changed.empty?
    Event.record("product.updated", subject: self, actor: Current.user, payload: { changed: changed.sort })
  end
end
