# frozen_string_literal: true

# Imagem usada no conteúdo da vitrine. Escopada por empreendimento (ADR 0005):
# o documento só aceita imagens do próprio empreendimento.
class ContentImage < ApplicationRecord
  include EnterpriseScoped

  MAX_PER_ENTERPRISE = 12

  has_one_attached :file do |attachable|
    attachable.variant :content, resize_to_limit: ImageVariants::CONTENT_LIMIT, **ImageVariants::JPEG, preprocessed: true
  end

  validates :file, image_upload: { required: true }
  validate :limit_per_enterprise, on: :create

  after_create { Event.record("content_image.created", subject: enterprise, actor: Current.user, payload: { content_image_id: id }) }
  after_create_commit :measure
  after_destroy { Event.record("content_image.removed", subject: enterprise, actor: Current.user, payload: { content_image_id: id }) }

  def signed_id_for_document = file.blob.signed_id

  def self.find_by_signed_id(signed_id)
    blob = ActiveStorage::Blob.find_signed(signed_id)
    return nil unless blob
    joins(:file_attachment).find_by(active_storage_attachments: { blob_id: blob.id })
  end

  private

  # Dimensões para <img width height> (evita salto de layout em 3G). A análise
  # do Active Storage é assíncrona; aqui é síncrona e curta.
  def measure
    blob = file.blob
    blob.analyze unless blob.analyzed?
    update_columns(width: blob.metadata["width"], height: blob.metadata["height"])
  end

  def limit_per_enterprise
    return unless enterprise && enterprise.content_images.count >= MAX_PER_ENTERPRISE
    errors.add(:base, "Sua página já tem #{MAX_PER_ENTERPRISE} fotos. Remova alguma para enviar outra.")
  end
end
