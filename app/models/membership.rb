# Pessoa ↔ empreendimento (Epic 1.1). Escopado (ADR 0005).
class Membership < ApplicationRecord
  include EnterpriseScoped

  belongs_to :user

  validates :user_id, uniqueness: { scope: :enterprise_id, message: "já faz parte deste empreendimento" }
  before_destroy :not_the_last_member

  after_create { Event.record("enterprise.member_added", subject: enterprise, actor: Current.user, payload: { user_id: }) }
  after_destroy { Event.record("enterprise.member_removed", subject: enterprise, actor: Current.user, payload: { user_id: }) }

  private

  def not_the_last_member
    return if enterprise.memberships.where.not(id:).exists?
    errors.add(:base, "Um empreendimento precisa ter pelo menos uma pessoa.")
    throw :abort
  end
end
