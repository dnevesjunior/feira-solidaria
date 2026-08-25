# frozen_string_literal: true

# Regras compartilhadas de imagem (ADR 0010): fotos vêm de celular com 4–8 MB;
# servir comprimido é requisito, não polimento (CLAUDE.md §3.6). `strip`
# remove EXIF — que carrega GPS (§3.3).
module ImageVariants
  JPEG = { format: :jpeg, saver: { quality: 80, strip: true } }.freeze
  CONTENT_LIMIT = [ 1600, 1600 ].freeze

  ACCEPTED_TYPES = %w[image/jpeg image/png image/webp].freeze
  MAX_BYTES = 10.megabytes
end
