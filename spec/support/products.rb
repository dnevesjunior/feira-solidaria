module ProductHelpers
  def create_product(enterprise, name: "Bolo de fubá", price: "25,00", publish: true, photo: publish, **attrs)
    product = Product.new(enterprise:, name:, **attrs)
    product.price_input = price
    product.photos.attach(jpeg_upload(width: 400, height: 300)) if photo
    product.save!
    product.publish! if publish
    product
  end
end

RSpec.configure { |c| c.include ProductHelpers }
