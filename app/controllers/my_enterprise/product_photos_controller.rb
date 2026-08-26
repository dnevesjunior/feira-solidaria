class MyEnterprise::ProductPhotosController < MyEnterprise::BaseController
  def destroy
    product = enterprise.products.find(params[:product_id])
    photo = product.photos.find(params[:id])
    if product.published? && product.photos.size == 1
      redirect_to edit_my_enterprise_product_path(product), alert: "Um produto publicado precisa de ao menos uma foto. Pause o produto ou envie outra foto antes."
      return
    end
    photo.purge_later
    Event.record("product.photo_removed", subject: product, actor: Current.user)
    redirect_to edit_my_enterprise_product_path(product), notice: t("products.photo_removed")
  end
end
