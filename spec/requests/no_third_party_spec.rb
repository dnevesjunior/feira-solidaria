require "rails_helper"

# CLAUDE.md §3.3: nenhuma requisição de terceiro sai da página.
RSpec.describe "Sem recursos de terceiros" do
  it "a página de entrada só referencia o próprio host" do
    get new_session_path
    external = response.body.scan(%r{(?:src|href)=["'](https?://[^"']+)}i).flatten
      .reject { |url| url.start_with?("http://www.example.com") }
    expect(external).to be_empty, "referências externas: #{external.join(', ')}"
  end
end
