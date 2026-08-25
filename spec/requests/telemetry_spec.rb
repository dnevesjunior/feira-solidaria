require "rails_helper"

RSpec.describe "Telemetria própria (ADR 0008)" do
  it "conta visitas por caminho e dia, numa única linha, sem nada por requisição" do
    2.times { get root_path, headers: { "User-Agent" => "Mozilla/5.0 (Linux; Android 10)" } }
    expect(PageView.count).to eq(1)
    view = PageView.first
    expect(view.path).to eq("/")
    expect(view.day).to eq(Date.current)
    expect(view.count).to eq(2)
    expect(PageView.column_names).to contain_exactly("id", "path", "day", "count")
  end

  it "ignora bots óbvios" do
    get root_path, headers: { "User-Agent" => "Googlebot/2.1" }
    expect(PageView.count).to eq(0)
  end

  it "não conta redirecionamentos" do
    get account_path
    expect(PageView.count).to eq(0)
  end
end
