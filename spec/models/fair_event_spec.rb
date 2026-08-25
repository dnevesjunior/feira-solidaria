require "rails_helper"

RSpec.describe FairEvent do
  it "mostra a próxima feira a partir de hoje" do
    FairEvent.create!(starts_at: 3.days.ago, place: "Praça antiga")
    proxima = FairEvent.create!(starts_at: 2.days.from_now, place: "Praça da Igreja")
    FairEvent.create!(starts_at: 9.days.from_now, place: "Outra praça")
    expect(FairEvent.next).to eq(proxima)
  end

  it "exige fim depois do início e registra eventos" do
    f = FairEvent.new(starts_at: Time.current, ends_at: 1.hour.ago, place: "x")
    expect(f).not_to be_valid
    f = FairEvent.create!(starts_at: 1.day.from_now, place: "Praça")
    f.update!(place: "Outra")
    expect(Event.where(subject: f).pluck(:kind)).to eq(%w[fair_event.created fair_event.updated])
  end
end
