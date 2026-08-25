# "Próxima feira": data e local da feira presencial. Dado da rede, editável por
# qualquer membro logado (Epic 1; revisão 2.5 — sem papel privilegiado).
class FairEvent < ApplicationRecord
  validates :starts_at, :place, presence: true
  validates :place, length: { maximum: 120 }
  validates :notes, length: { maximum: 500 }, allow_nil: true
  validate :ends_after_starts

  after_create { Event.record("fair_event.created", subject: self, actor: Current.user) }
  after_update { Event.record("fair_event.updated", subject: self, actor: Current.user) }

  scope :upcoming, -> { where(starts_at: Time.current.beginning_of_day..).order(:starts_at) }

  def self.next = upcoming.first

  private

  def ends_after_starts
    return if ends_at.blank? || starts_at.blank? || ends_at > starts_at
    errors.add(:ends_at, "precisa ser depois do início")
  end
end
