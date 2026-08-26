# Categoria de produto: lista curta e fechada, definida com a feira (Epic 2.3).
# Sem UI de criação — entra por seed quando a feira decidir. Organiza; nunca
# prioriza.
class Category < ApplicationRecord
  has_many :products, dependent: :nullify

  validates :name, presence: true, uniqueness: true
  validates :slug, presence: true, uniqueness: true, format: { with: Enterprise::Slug::FORMAT }

  before_validation { self.slug = Enterprise::Slug.generate(name) if slug.blank? && name.present? }

  scope :ordered, -> { order(:position, :name) }

  def to_param = slug
end
