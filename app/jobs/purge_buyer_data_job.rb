# Expurgo de dados de comprador (ADR 0016): 90 dias após o pedido fechar, ou
# 180 dias em qualquer estado. O pedido fica; o dado pessoal não.
class PurgeBuyerDataJob < ApplicationJob
  queue_as :default

  def perform
    purged = 0
    Order.due_for_purge.find_each { |order| order.purge_buyer_data!; purged += 1 }
    Rails.logger.info("PurgeBuyerDataJob: #{purged} pedido(s) expurgado(s)")
    purged
  end
end
