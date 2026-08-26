# frozen_string_literal: true

# Versão de ImageUploadValidator para has_many_attached (ADR 0010).
#
#   validates :photos, image_uploads: { max: 4 }
class ImageUploadsValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, attached)
    return unless attached.attached?

    blobs = attached.map(&:blob)
    if options[:max] && blobs.size > options[:max]
      record.errors.add(attribute, "podem ser no máximo #{options[:max]}")
    end
    blobs.each do |blob|
      unless ImageVariants::ACCEPTED_TYPES.include?(blob.content_type)
        record.errors.add(attribute, "precisam ser fotos em JPG, PNG ou WebP")
        break
      end
      if blob.byte_size >= ImageVariants::MAX_BYTES
        record.errors.add(attribute, "precisam ter menos de 10 MB cada")
        break
      end
    end
  end
end
