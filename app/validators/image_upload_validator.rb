# frozen_string_literal: true

# Valida um anexo de imagem antes de gravar (ADR 0010): tipo aceito e tamanho
# máximo. Mensagens dizem o que fazer, não só o que deu errado (Epic 1.4).
#
#   validates :cover_image, image_upload: true
#   validates :file, image_upload: { required: true }
class ImageUploadValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, attached)
    unless attached.attached?
      record.errors.add(attribute, "precisa ser enviada") if options[:required]
      return
    end

    blob = attached.blob
    unless ImageVariants::ACCEPTED_TYPES.include?(blob.content_type)
      record.errors.add(attribute, "precisa ser uma foto em JPG, PNG ou WebP")
    end
    if blob.byte_size >= ImageVariants::MAX_BYTES
      record.errors.add(attribute, "precisa ter menos de 10 MB")
    end
  end
end
