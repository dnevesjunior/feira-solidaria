# Upload do EditorJS (Epic 1.3). Responde no formato que o tool de imagem espera.
class MyEnterprise::ContentImagesController < MyEnterprise::BaseController
  def create
    image = ContentImage.new(enterprise:, file: params[:image])
    if image.save
      render json: { success: 1, file: { url: url_for(image.file.variant(:content)), signed_id: image.signed_id_for_document, width: image.width, height: image.height } }
    else
      render json: { success: 0, message: image.errors.full_messages.join(". ") }, status: :unprocessable_entity
    end
  end
end
