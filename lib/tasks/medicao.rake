# Medição do sucesso da v1 (Epic 3; CLAUDE.md §2; revisão 2.6): "as famílias
# venderam mais do que venderiam sem a plataforma — dentro da capacidade que
# declararam?". Relatório de produto, só leitura, rede inteira, sem ranking
# por loja. Comparar com docs/operacao/linha-de-base.md.
namespace :medicao do
  desc "Relatório mensal da v1: pedidos por estado, desfecho, total concluído, aberto acima da capacidade"
  task v1: :environment do
    puts "Medição da v1 — rede inteira — gerado em #{I18n.l(Time.current, format: :long)}"
    puts

    Order.group("date_trunc('month', orders.created_at)").order(Arel.sql("1")).count.each_key do |month|
      scope = Order.where(created_at: month.all_month)
      concluded = scope.where(status: "completed")
      total = concluded.sum(:total_cents)
      total = Amount.brl(total) unless total.is_a?(Amount) # a coluna tipada já devolve Amount quando há linhas
      puts I18n.l(month.to_date, format: "%B de %Y").capitalize
      puts "  pedidos criados:      #{scope.count}"
      puts "  WhatsApp aberto:      #{scope.where.not(routed_at: nil).count}"
      puts "  confirmados:          #{scope.where.not(confirmed_at: nil).count}"
      puts "  concluídos:           #{concluded.count}  (#{total})"
      Order::OUTCOMES.each do |o|
        puts "    desfecho #{{ 'full' => 'pago e entregue', 'partial' => 'parcial        ', 'none' => 'não            ' }[o]}: #{concluded.where(outcome: o).count}"
      end
      puts "  recusados/cancelados: #{scope.where(status: %w[refused cancelled]).count}"
      puts "  empreendimentos com pedido: #{scope.distinct.count(:enterprise_id)}"
      puts
    end

    puts "Pedidos abertos acima da capacidade declarada, hoje (revisão 2.6):"
    warnings = Enterprise.published.flat_map { |e| Order::CapacityWarning.for(e) }
    if warnings.empty?
      puts "  nenhum"
    else
      puts "  #{warnings.size} produto(s) em #{warnings.map { |w| w.product.enterprise_id }.uniq.size} empreendimento(s)"
    end
    puts
    puts "Linha de base pré-plataforma: docs/operacao/linha-de-base.md"
  end
end
