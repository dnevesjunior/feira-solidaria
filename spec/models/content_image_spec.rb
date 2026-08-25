require "rails_helper"

RSpec.describe ContentImage do
  let(:enterprise) { create_enterprise }

  it "é escopada e guarda as dimensões" do
    expect(ContentImage).to include(EnterpriseScoped)
    image = attach_content_image(enterprise, width: 640, height: 480)
    expect([ image.width, image.height ]).to eq([ 640, 480 ])
  end

  it "aceita uma foto de celular com mais de 6 MB e a serve comprimida" do
    # Ruído gaussiano é o pior caso para JPEG; uma foto real comprime bem mais.
    # O que se prova aqui: aceita > 6 MB, reduz a ≤ 1600 px e corta o peso a uma fração.
    image = attach_content_image(enterprise, width: 3000, height: 2250, megabytes: 6)
    original = image.file.blob.byte_size
    expect(original).to be > 6.megabytes
    variant = image.file.variant(:content).processed
    expect(variant.image.blob.byte_size).to be < 1.megabyte
    expect(variant.image.blob.byte_size).to be < original * 0.2
    expect(Vips::Image.new_from_buffer(variant.image.blob.download, "").width).to be <= 1600
  end

  it "recusa mais de 12 por empreendimento" do
    allow(enterprise.content_images).to receive(:count).and_return(12)
    image = ContentImage.new(enterprise:, file: jpeg_upload)
    expect(image).not_to be_valid
    expect(image.errors[:base].join).to match(/12 fotos/)
  end

  it "exige o arquivo e o tipo certo" do
    expect(ContentImage.new(enterprise:)).not_to be_valid
    image = ContentImage.new(enterprise:)
    image.file.attach(io: StringIO.new("GIF89a"), filename: "x.gif", content_type: "image/gif")
    expect(image).not_to be_valid
    expect(image.errors[:file].join).to match(/JPG/)
  end
end
