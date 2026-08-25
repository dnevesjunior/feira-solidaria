# "Próxima feira": qualquer membro logado cadastra e edita (revisão 2.5).
class FairEventsController < ApplicationController
  def index
    @fair_events = FairEvent.upcoming
  end

  def new
    @fair_event = FairEvent.new(starts_at: next_saturday_morning)
  end

  def create
    @fair_event = FairEvent.new(fair_event_params)
    if @fair_event.save
      redirect_to fair_events_path, notice: t("fair_events.saved")
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @fair_event = FairEvent.find(params[:id])
  end

  def update
    @fair_event = FairEvent.find(params[:id])
    if @fair_event.update(fair_event_params)
      redirect_to fair_events_path, notice: t("fair_events.saved")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def fair_event_params
    params.require(:fair_event).permit(:starts_at, :ends_at, :place, :notes)
  end

  def next_saturday_morning
    date = Date.current.next_occurring(:saturday)
    Time.zone.local(date.year, date.month, date.day, 9)
  end
end
