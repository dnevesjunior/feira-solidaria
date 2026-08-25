require_relative "boot"

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "active_storage/engine"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_view/railtie"
# require "action_cable/engine"  # sem Action Cable: peso sem uso (CLAUDE.md §3.6)
# require "rails/test_unit/railtie"  # testes com RSpec (ADR 0002)

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module FeiraSolidaria
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.1

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Contexto de uso: Baixada Santista, SP (CLAUDE.md §5).
    config.time_zone = "America/Sao_Paulo"
    config.i18n.default_locale = :"pt-BR"
    config.i18n.available_locales = [ :"pt-BR" ]

    # O log de eventos usa trigger no PostgreSQL (ADR 0006); schema.rb não
    # representa triggers, structure.sql sim.
    config.active_record.schema_format = :sql

    # Testes com RSpec (ADR 0002). Sem system tests gerados automaticamente:
    # os testes de sistema são escritos à mão para os critérios de "pronto".
    config.generators do |g|
      g.test_framework :rspec, fixtures: false, view_specs: false, helper_specs: false, routing_specs: false
      g.system_tests nil
    end
  end
end
