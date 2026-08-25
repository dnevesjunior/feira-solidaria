# Testes de sistema sem JavaScript por padrão: rack_test é rápido e não
# precisa de navegador. Use `js: true` para Selenium quando houver Stimulus.
RSpec.configure do |config|
  config.before(:each, type: :system) do
    driven_by :rack_test
  end

  config.before(:each, type: :system, js: true) do
    driven_by :selenium, using: :headless_chrome, screen_size: [ 412, 915 ] # Android modesto
  end
end
