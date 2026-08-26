# frozen_string_literal: true

# Empreendimento: unidade familiar ou coletiva membro da rede (CLAUDE.md §4).
# Raiz do escopo por empreendimento (ADR 0005). Nasce em rascunho; publicar é
# um ato deliberado (Epic 1, nota de desenho).
class Enterprise < ApplicationRecord
  STATUSES = %w[draft published].freeze

  has_many :memberships, dependent: :destroy
  has_many :users, through: :memberships
  has_many :content_images, dependent: :destroy
  has_many :products, dependent: :destroy
  has_many :orders, dependent: :destroy

  has_one_attached :profile_image do |attachable|
    attachable.variant :profile, resize_to_fill: [ 400, 400 ], **ImageVariants::JPEG, preprocessed: true
    attachable.variant :thumb, resize_to_fill: [ 320, 320 ], **ImageVariants::JPEG, preprocessed: true
  end
  has_one_attached :cover_image do |attachable|
    attachable.variant :cover, resize_to_fill: [ 1200, 630 ], **ImageVariants::JPEG, preprocessed: true
  end

  normalizes :whatsapp, with: ->(raw) { PhoneNumber.normalize(raw) || raw.to_s.strip }
  normalizes :instagram, with: ->(raw) { raw.to_s.strip.delete_prefix("@").sub(%r{\Ahttps?://(www\.)?instagram\.com/}, "").delete_suffix("/").presence }
  normalizes :short_description, :neighborhood, with: ->(raw) { raw.to_s.strip.presence }

  validates :name, presence: true, length: { in: 3..60 }
  validates :short_description, length: { maximum: 200 }, allow_nil: true
  validates :neighborhood, length: { maximum: 60 }, allow_nil: true
  validates :instagram, format: { with: /\A[\w.]{1,30}\z/ }, allow_nil: true
  validates :whatsapp, presence: true
  validate :whatsapp_is_valid
  validates :status, inclusion: { in: STATUSES }
  validates :slug, presence: true, uniqueness: true
  validate :slug_is_speakable
  validate :slug_is_immutable_after_publish, on: :update
  validate :content_is_a_valid_document
  validates :profile_image, :cover_image, image_upload: true

  before_validation :generate_slug, if: -> { slug.blank? && name.present? }

  after_create { Event.record("enterprise.created", subject: self, actor: Current.user) }
  after_update :record_updated_event

  scope :published, -> { where(status: "published") }

  def draft? = status == "draft"
  def published? = status == "published"

  def publish!
    transaction do
      update!(status: "published", published_at: Time.current)
      Event.record("enterprise.published", subject: self, actor: Current.user)
    end
  end

  def unpublish!
    transaction do
      update!(status: "draft")
      Event.record("enterprise.unpublished", subject: self, actor: Current.user)
    end
  end

  def document = EditorJs::Document.new(content, enterprise: self)

  def to_param = slug

  # Visitas à própria vitrine (ADR 0008): só a própria loja vê, nunca comparativo.
  def page_views_last_30_days
    PageView.where(path: "/#{slug}", day: 30.days.ago.to_date..Date.current).sum(:count)
  end

  private

  def generate_slug
    self.slug = Enterprise::Slug.generate(name, taken: ->(candidate) { Enterprise.where(slug: candidate).where.not(id:).exists? })
  end

  def whatsapp_is_valid
    return if whatsapp.blank? || PhoneNumber.valid?(whatsapp)
    errors.add(:whatsapp, :invalid)
  end

  def slug_is_speakable
    return if slug.blank?
    errors.add(:slug, :invalid) unless Enterprise::Slug.valid?(slug)
    errors.add(:slug, :reserved) if Enterprise::Slug.reserved?(slug)
  end

  def slug_is_immutable_after_publish
    return unless slug_changed? && status_was == "published"
    errors.add(:slug, :immutable_after_publish)
  end

  def content_is_a_valid_document
    doc = EditorJs::Document.new(content, enterprise: self)
    doc.errors.each { |message| errors.add(:content, message) }
  end

  def record_updated_event
    changed = saved_changes.keys - %w[updated_at status published_at content]
    changed << "content" if saved_change_to_content?
    return if changed.empty?
    Event.record("enterprise.updated", subject: self, actor: Current.user, payload: { changed: changed.sort })
  end
end
