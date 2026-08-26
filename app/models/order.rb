# frozen_string_literal: true

# Pedido: intenção de compra roteada para UM empreendimento (Epic 3). A
# plataforma registra e acompanha; a liquidação acontece fora (Pix, dinheiro,
# entrega). Sem gateway, sem carteira (CLAUDE.md §3.1).
#
# Ciclo curto e manual: recebido → confirmado → concluído; ramos recusado e
# cancelado. Nada é inferido por prazo. "Roteado" = o comprador abriu o
# WhatsApp; não significa que a loja leu (ADR 0015).
class Order < ApplicationRecord
  include EnterpriseScoped

  STATUSES = %w[received confirmed completed refused cancelled].freeze
  OPEN_STATUSES = %w[received confirmed].freeze
  OUTCOMES = %w[full partial none].freeze
  RETENTION_AFTER_CLOSE = 90.days
  RETENTION_MAX = 180.days

  attribute :total_cents, :amount, unit: :brl
  def total = total_cents

  has_many :items, class_name: "OrderItem", dependent: :destroy

  normalizes :buyer_phone, with: ->(raw) { PhoneNumber.normalize(raw) || raw.to_s.strip }
  normalizes :buyer_name, with: ->(raw) { raw.to_s.squish.presence }
  normalizes :buyer_note, :outcome_note, with: ->(raw) { raw.to_s.strip.presence }

  validates :token, presence: true, uniqueness: true
  validates :status, inclusion: { in: STATUSES }
  validates :outcome, inclusion: { in: OUTCOMES }, allow_nil: true
  validates :buyer_note, length: { maximum: 500 }, allow_nil: true
  validates :outcome_note, length: { maximum: 300 }, allow_nil: true
  with_options unless: :buyer_purged_at do
    validates :buyer_name, presence: true, length: { in: 2..80 }
    validates :buyer_phone, presence: true
    validate :buyer_phone_is_valid
  end
  validate :has_items, on: :create
  validate :total_matches_items, on: :create

  before_validation { self.token ||= SecureRandom.base58(20) }

  after_create { Event.record("order.created", subject: self, actor: nil, payload: { item_count: items.size, total_cents: total.value }) }

  scope :open, -> { where(status: OPEN_STATUSES) }
  scope :closed, -> { where.not(closed_at: nil) }
  scope :recent_first, -> { order(created_at: :desc) }

  STATUSES.each { |s| define_method(:"#{s}?") { status == s } }
  def open? = OPEN_STATUSES.include?(status)
  def routed? = routed_at.present?

  # Código curto e não sequencial, para a conversa no WhatsApp.
  def code = "F-#{token[0, 5].upcase}"
  def to_param = token

  def self.build_from_cart_group(enterprise:, items:, buyer_name:, buyer_phone:, buyer_note:)
    order = new(enterprise:, buyer_name:, buyer_phone:, buyer_note:)
    total = Amount.zero(:brl)
    items.each do |product, quantity|
      line = order.items.build(product:, product_name: product.name, sale_unit: product.sale_unit,
        unit_price_cents: product.price, quantity:)
      total += line.subtotal
    end
    order.total_cents = total
    order
  end

  def route!
    return if routed?
    transaction do
      update!(routed_at: Time.current)
      Event.record("order.routed", subject: self)
    end
  end

  def confirm!
    transition!(from: %w[received], to: "confirmed", event: "order.confirmed") { self.confirmed_at = Time.current }
  end

  def complete!(outcome:, note: nil)
    raise ArgumentError, "desfecho inválido: #{outcome.inspect}" unless OUTCOMES.include?(outcome.to_s)
    transition!(from: OPEN_STATUSES, to: "completed", event: "order.completed", payload: { outcome: outcome.to_s }) do
      self.outcome = outcome.to_s
      self.outcome_note = note
      self.closed_at = Time.current
    end
    Event.record("order.outcome_recorded", subject: self, actor: Current.user, payload: { outcome: outcome.to_s })
  end

  def refuse!
    transition!(from: OPEN_STATUSES, to: "refused", event: "order.refused") { self.closed_at = Time.current }
  end

  def cancel!
    transition!(from: OPEN_STATUSES, to: "cancelled", event: "order.cancelled") { self.closed_at = Time.current }
  end

  # Expurgo do dado pessoal (ADR 0016). O pedido e seu estado ficam.
  def purge_buyer_data!
    return if buyer_purged_at
    transaction do
      update!(buyer_name: nil, buyer_phone: nil, buyer_note: nil, buyer_purged_at: Time.current)
      Event.record("order.buyer_data_purged", subject: self)
    end
  end

  def self.due_for_purge(now: Time.current)
    where(buyer_purged_at: nil).where(
      "closed_at < :closed OR created_at < :created", closed: now - RETENTION_AFTER_CLOSE, created: now - RETENTION_MAX
    )
  end

  def whatsapp_message(order_url) = Order::WhatsappMessage.new(self, order_url)

  private

  def transition!(from:, to:, event:, payload: {})
    raise InvalidTransition, "pedido #{code} está #{status}; não pode ir para #{to}" unless from.include?(status)
    transaction do
      yield if block_given?
      self.status = to
      save!
      Event.record(event, subject: self, actor: Current.user, payload:)
    end
  end

  class InvalidTransition < StandardError; end

  def buyer_phone_is_valid
    return if buyer_phone.blank? || PhoneNumber.valid?(buyer_phone)
    errors.add(:buyer_phone, :invalid)
  end

  def has_items
    errors.add(:base, "O pedido precisa ter ao menos um item.") if items.empty?
  end

  def total_matches_items
    return if items.empty? || total_cents.nil?
    sum = items.map(&:subtotal).reduce(Amount.zero(:brl), :+)
    errors.add(:total_cents, "não bate com os itens") unless sum == total
  end
end
