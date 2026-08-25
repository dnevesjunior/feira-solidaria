# Próxima feira: sábado que vem, de manhã.
if FairEvent.upcoming.none?
  date = Date.current.next_occurring(:saturday)
  FairEvent.create!(
    starts_at: Time.zone.local(date.year, date.month, date.day, 9),
    ends_at: Time.zone.local(date.year, date.month, date.day, 13),
    place: "Praça da Igreja, Vila Gilda — Santos",
    notes: "Traga sua sacola. Aceitamos Chiquinho."
  )
end
f = FairEvent.next
puts "  próxima feira: #{I18n.l(f.starts_at, format: :fair)} — #{f.place}"
