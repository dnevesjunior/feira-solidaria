class CartItemsController < ApplicationController
  allow_unauthenticated_access

  def create
    product = Product.published.joins(:enterprise).merge(Enterprise.published).find(params[:product_id])
    cart.add(product.id, params.fetch(:quantity, 1))
    redirect_back_or_to cart_path, notice: t("cart.added", name: product.name)
  end

  def update
    cart.set(params[:id], params[:quantity])
    redirect_to cart_path
  end

  def destroy
    cart.remove(params[:id])
    redirect_to cart_path, notice: t("cart.removed")
  end
end
