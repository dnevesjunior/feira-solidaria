require "rails_helper"

RSpec.describe ErrorReport do
  it "grava erros reportados ao Rails.error, com telefone e e-mail removidos" do
    Rails.error.handle(RuntimeError) do
      raise "falhou para +55 13 99999-0001 e maria@example.com"
    end

    report = ErrorReport.last
    expect(report.exception_class).to eq("RuntimeError")
    expect(report.message).not_to include("99999")
    expect(report.message).not_to include("example.com")
    expect(report.message).to include("[removido]")
    expect(report.handled).to be(true)
  end

  it "expurga relatórios com mais de 90 dias" do
    ErrorReport.create!(exception_class: "X", occurred_at: 91.days.ago)
    ErrorReport.create!(exception_class: "Y", occurred_at: 1.day.ago)
    expect { ErrorReport.purge_expired! }.to change(ErrorReport, :count).by(-1)
  end
end
