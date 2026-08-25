# frozen_string_literal: true

# Query object escopado a um empreendimento (ADR 0005). Recebe o
# empreendimento no construtor; nunca o lê de params.
class EnterpriseQuery < ApplicationQuery
  attr_reader :enterprise

  def initialize(enterprise = Current.enterprise)
    raise EnterpriseScoped::MissingScope, "#{self.class} sem empreendimento" if enterprise.nil?
    @enterprise = enterprise
  end
end
