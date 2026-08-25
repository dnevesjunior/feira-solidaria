require "stringio"

module EnterpriseHelpers
  def create_enterprise(name: "Doces da Cida", whatsapp: "13 99999-0001", user: nil, **attrs)
    enterprise = Enterprise.create!(name:, whatsapp:, **attrs)
    enterprise.memberships.create!(user: user || create_user(phone: "13 9#{format('%08d', rand(10**8))}"))
    enterprise
  end

  def publish(enterprise)
    enterprise.publish!
    enterprise
  end

  # JPEG gerado com vips; `megabytes` pede um arquivo pesado (ruído, qualidade 100).
  def jpeg_upload(width: 640, height: 480, megabytes: nil, name: "foto.jpg")
    require "vips"
    image = megabytes ? Vips::Image.gaussnoise(width, height, sigma: 80, mean: 128) : Vips::Image.black(width, height).draw_rect([ 200, 120, 60 ], 0, 0, width, height, fill: true)
    image = image.bandjoin([ image, image ]) if image.bands == 1
    data = image.write_to_buffer(".jpg", Q: megabytes ? 100 : 85, strip: true)
    Rack::Test::UploadedFile.new(StringIO.new(data), "image/jpeg", original_filename: name)
  end

  def attach_content_image(enterprise, **opts)
    ContentImage.create!(enterprise:, file: jpeg_upload(**opts))
  end
end

RSpec.configure { |c| c.include EnterpriseHelpers }
