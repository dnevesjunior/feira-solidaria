# Registra o tipo :amount (ADR 0004). Em to_prepare para sobreviver ao reload.
Rails.application.config.to_prepare do
  ActiveRecord::Type.register(:amount, Amount::Type, override: true)
end
