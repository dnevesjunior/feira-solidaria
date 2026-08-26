class CartsController < ApplicationController
  allow_unauthenticated_access

  def show
    @groups = cart.groups
  end
end
