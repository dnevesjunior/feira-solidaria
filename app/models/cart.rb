# frozen_string_literal: true

# Cesta leve, na sessão, sem login e sem identificação entre visitas (Epic
# 3.1; ADR 0016). Só produtos publicados de lojas publicadas; o resto some.
class Cart
  MAX_ITEMS = 30
  MAX_QUANTITY = 99

  Line = Data.define(:product, :quantity) do
    def subtotal = product.price * quantity
  end

  def initialize(session)
    @session = session
    @session[:cart] = {} unless @session[:cart].is_a?(Hash)
  end

  def add(product_id, quantity = 1)
    change(product_id) { |current| current + quantity.to_i }
  end

  def set(product_id, quantity) = change(product_id) { quantity.to_i }
  def remove(product_id) = @session[:cart].delete(product_id.to_s)
  def clear = @session[:cart] = {}
  def empty? = lines.empty?
  def count = lines.sum(&:quantity)

  def lines
    @lines ||= begin
      products = Product.published.joins(:enterprise).merge(Enterprise.published)
        .includes(:enterprise).where(id: @session[:cart].keys).index_by { |p| p.id.to_s }
      @session[:cart].keys.each { |id| @session[:cart].delete(id) unless products.key?(id) }
      @session[:cart].filter_map { |id, qty| products[id] && Line.new(product: products[id], quantity: qty.to_i.clamp(1, MAX_QUANTITY)) }
    end
  end

  # Itens por empreendimento: cada grupo vira um pedido separado (Epic 3, fora de escopo do coletivo).
  def groups = lines.group_by { |line| line.product.enterprise }
  def multiple_enterprises? = groups.size > 1
  def total = lines.map(&:subtotal).reduce(Amount.zero(:brl), :+)

  private

  def change(product_id)
    key = product_id.to_s
    quantity = yield(@session[:cart][key].to_i)
    if quantity <= 0
      @session[:cart].delete(key)
    elsif @session[:cart].key?(key) || @session[:cart].size < MAX_ITEMS
      @session[:cart][key] = quantity.clamp(1, MAX_QUANTITY)
    end
    @lines = nil
  end
end
