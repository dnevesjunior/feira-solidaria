class MyEnterprise::EnterprisesController < MyEnterprise::BaseController
  skip_before_action :set_current_enterprise, only: %i[ new create ]

  def show
    @enterprise = enterprise
    @views = @enterprise.page_views_last_30_days
  end

  def new
    @enterprise = Enterprise.new(whatsapp: Current.user.phone)
  end

  def create
    @enterprise = Enterprise.new(basic_params)
    Enterprise.transaction do
      @enterprise.save!
      @enterprise.memberships.create!(user: Current.user)
    end
    session[:enterprise_id] = @enterprise.id
    redirect_to my_enterprise_edit_path, notice: t("my_enterprise.created")
  rescue ActiveRecord::RecordInvalid
    render :new, status: :unprocessable_entity
  end

  def edit
    @enterprise = enterprise
  end

  def update
    @enterprise = enterprise
    if @enterprise.update(update_params)
      redirect_to my_enterprise_path, notice: t("my_enterprise.saved")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def preview
    @enterprise = enterprise
    @document = @enterprise.document
    @html = EditorJs::Renderer.new(@document).to_html
    @products = @enterprise.products.visible.by_name.with_attached_photos
    @preview = true
    render "enterprises/show"
  end

  def publish
    enterprise.publish!
    redirect_to my_enterprise_path, notice: t("my_enterprise.published", url: enterprise_url(enterprise.slug))
  end

  def unpublish
    enterprise.unpublish!
    redirect_to my_enterprise_path, notice: t("my_enterprise.unpublished")
  end

  # Exportação completa, acessível ao próprio empreendimento (CLAUDE.md §3.3).
  def export
    zip = EnterpriseExport.new(enterprise).to_zip
    Event.record("enterprise.exported", subject: enterprise, actor: Current.user)
    send_data zip, filename: "#{enterprise.slug}-#{Date.current.iso8601}.zip", type: "application/zip"
  end

  private

  def basic_params
    params.require(:enterprise).permit(:name, :whatsapp, :short_description, :neighborhood, :instagram)
  end

  def update_params
    permitted = basic_params.merge(params.require(:enterprise).permit(:profile_image, :cover_image))
    permitted[:slug] = params[:enterprise][:slug] if enterprise.draft? && params[:enterprise].key?(:slug)
    permitted[:content] = parse_content(params[:enterprise][:content]) if params[:enterprise].key?(:content)
    permitted
  end

  def parse_content(raw)
    JSON.parse(raw.to_s)
  rescue JSON::ParserError
    { "blocks" => "inválido" } # o documento reporta o erro em português
  end
end
