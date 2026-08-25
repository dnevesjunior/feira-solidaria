# Imagens (ADR 0010): servidas por proxy — uma requisição em vez de redirect +
# download, o que importa em 3G. Variantes com vips, JPEG q80, sem EXIF.
Rails.application.config.active_storage.resolve_model_to_route = :rails_storage_proxy
Rails.application.config.active_storage.variant_processor = :vips
