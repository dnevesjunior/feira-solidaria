class MyEnterprise::ProductsController < MyEnterprise::BaseController
  before_action :set_product, only: %i[ edit update destroy publish pause unpause ]

  def index
    @products = enterprise.products.by_name.with_attached_photos
    @groups = { "draft" => [], "published" => [], "paused" => [] }
    @products.each { |p| @groups[p.status] << p }
  end

  def new
    @product = enterprise.products.new(capacity_period: "week")
  end

  def create
    @product = enterprise.products.new(product_params)
    if @product.save
      redirect_to my_enterprise_products_path, notice: t("products.created")
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @product.update(product_params)
      redirect_to my_enterprise_products_path, notice: t("products.saved")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @product.destroy!
    redirect_to my_enterprise_products_path, notice: t("products.removed")
  end

  def publish
    if @product.draft? || @product.paused?
      @product.publish!
      redirect_to my_enterprise_products_path, notice: t("products.published")
    else
      redirect_to my_enterprise_products_path
    end
  rescue ActiveRecord::RecordInvalid => e
    redirect_to edit_my_enterprise_product_path(@product), alert: e.record.errors.full_messages.join(". ")
  end

  def pause
    @product.pause!
    redirect_to my_enterprise_products_path, notice: t("products.paused")
  end

  def unpause
    @product.unpause!
    redirect_to my_enterprise_products_path, notice: t("products.unpaused")
  end

  private

  def set_product
    @product = enterprise.products.find(params[:id])
  end

  def product_params
    permitted = params.require(:product).permit(:name, :description, :price_input, :sale_unit, :sale_unit_other,
      :capacity_quantity, :capacity_period, :lead_time_days, :category_id, photos: [])
    permitted[:sale_unit] = permitted.delete(:sale_unit_other) if permitted[:sale_unit] == "outra"
    permitted.delete(:sale_unit_other)
    permitted.delete(:photos) if permitted[:photos].blank? || permitted[:photos].all?(&:blank?)
    permitted
  end
end
