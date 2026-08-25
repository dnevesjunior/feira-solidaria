# Conta de membro (ADR 0007). Identificada por telefone; e-mail opcional.
class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :memberships, dependent: :destroy
  has_many :enterprises, through: :memberships

  normalizes :phone, with: ->(raw) { PhoneNumber.normalize(raw) || raw.to_s.strip }
  normalizes :email, with: ->(raw) { raw.to_s.strip.downcase.presence }

  validates :name, presence: true
  validates :phone, presence: true, uniqueness: true
  validate :phone_is_valid
  # Mínimo 8, sem regra de complexidade, espaços permitidos (ADR 0007).
  validates :password, length: { minimum: 8 }, allow_nil: true

  after_create :record_created_event

  def self.find_by_phone(raw) = find_by(phone: PhoneNumber.normalize(raw))

  private

  def phone_is_valid
    return if phone.blank? || PhoneNumber.valid?(phone)
    errors.add(:phone, :invalid)
  end

  def record_created_event
    Event.record("user.created", subject: self, actor: Current.user)
  end
end
