class ErrorsController < ApplicationController
  allow_unauthenticated_access

  def not_found
    render status: :not_found
  end
end
