# frozen_string_literal: true

# Base dos query objects (ADR 0005). Leituras que cruzam empreendimentos
# (hub, catálogo da feira, capacidade agregada) herdam daqui e dizem no nome o
# que fazem. Leituras de uma loja herdam de EnterpriseQuery.
class ApplicationQuery
  def self.call(...) = new(...).call

  def call
    raise NotImplementedError, "#{self.class}#call"
  end
end
