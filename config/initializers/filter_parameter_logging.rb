# Be sure to restart your server when you modify this file.

# Configure parameters to be partially matched (e.g. passw matches password) and filtered from the log file.
# Use this to limit dissemination of sensitive information.
# See the ActiveSupport::ParameterFilter documentation for supported notations and behaviors.
#
# Telefone e nome entram porque são o identificador e o dado pessoal dos
# membros (ADR 0007) e do comprador (Epic 3). Log não é lugar de dado pessoal
# (CLAUDE.md §3.3).
Rails.application.config.filter_parameters += [
  :passw, :email, :secret, :token, :_key, :crypt, :salt, :certificate, :otp, :ssn, :cvv, :cvc,
  :phone, :telefone, :name, :nome
]
