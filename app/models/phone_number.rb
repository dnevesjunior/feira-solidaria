# frozen_string_literal: true

# Normalização de telefone brasileiro para E.164 (ADR 0007). Sem gem: o
# domínio é um só país e o formato é estável.
#
#   PhoneNumber.normalize("(13) 99999-0001")  # => "+5513999990001"
#   PhoneNumber.normalize("13 3333 0001")      # => "+551333330001"
#   PhoneNumber.normalize("abc")               # => nil
module PhoneNumber
  DDI = "55"
  # DDD (dois dígitos, o primeiro não é zero), nono dígito opcional, oito dígitos.
  NATIONAL = /\A[1-9]\d9?\d{8}\z/

  def self.normalize(raw)
    return nil if raw.nil?
    digits = raw.to_s.gsub(/\D/, "")
    digits = digits.sub(/\A0+/, "")
    digits = digits.delete_prefix(DDI) if digits.length > 11 && digits.start_with?(DDI)
    return nil unless digits.match?(NATIONAL)
    "+#{DDI}#{digits}"
  end

  def self.valid?(raw) = !normalize(raw).nil?

  # "+5513999990001" => "(13) 99999-0001"
  def self.format(e164)
    national = e164.to_s.delete_prefix("+#{DDI}")
    return e164.to_s unless national.match?(NATIONAL)
    ddd, rest = national[0, 2], national[2..]
    "(#{ddd}) #{rest[0...-4]}-#{rest[-4..]}"
  end
end
