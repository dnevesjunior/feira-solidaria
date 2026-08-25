# Busca por nome sem sensibilidade a acento (Epic 1.2).
class EnableUnaccent < ActiveRecord::Migration[8.1]
  def change
    enable_extension "unaccent"
  end
end
