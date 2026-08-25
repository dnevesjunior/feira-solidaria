# frozen_string_literal: true

# Um parâmetro de governança em banco. Cada mudança é uma linha nova (nunca
# UPDATE); o vigente é o mais recente. O Epic 5 acrescenta autor, valor
# anterior, justificativa e o processo de assembleia — sem alterar este leitor.
class Governance::Parameter < ApplicationRecord
  self.table_name = "governance_parameters"

  validates :key, inclusion: { in: Governance::DEFAULTS.keys.map(&:to_s) }
  validates :value, presence: true

  def readonly? = persisted?

  def self.value_for(key)
    key = key.to_s
    raise ArgumentError, "parâmetro desconhecido: #{key}" unless Governance::DEFAULTS.key?(key.to_sym)
    where(key:).order(created_at: :desc, id: :desc).pick(:value) || Governance::DEFAULTS[key.to_sym]
  end
end
