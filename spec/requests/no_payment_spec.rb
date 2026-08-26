require "rails_helper"

# CLAUDE.md §3.1: a plataforma não intermedia pagamento. Nenhum gateway, nunca.
RSpec.describe "Sem pagamento" do
  it "não há gem nem código de gateway de pagamento" do
    lock = File.read(Rails.root.join("Gemfile.lock"))
    expect(lock).not_to match(/stripe|pagarme|pagar_me|mercadopago|mercado_pago|paypal|braintree|iugu|asaas|gerencianet|efi_pay|pix/i)
    # Identificadores de SDK, não palavras em comentários (os comentários dizem "sem gateway").
    sources = Dir[Rails.root.join("app/**/*.{rb,erb,js}")].map { |f| File.read(f) }.join
    expect(sources).not_to match(/\b(Stripe|PagarMe|MercadoPago|Braintree|PayPal|Iugu|Asaas)\b|payment_intent|checkout_session|create_charge|process_payment/)
  end

  it "o pedido não tem coluna de pagamento" do
    expect(Order.column_names.join).not_to match(/paid_at|payment|pix|card/)
  end
end
