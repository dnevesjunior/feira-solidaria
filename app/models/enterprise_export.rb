# frozen_string_literal: true

# Exportação completa do empreendimento, em zip, acessível ao próprio
# empreendimento sem pedir a ninguém (CLAUDE.md §3.3; ADR 0012). Portabilidade
# de verdade: dados, conteúdo bruto, eventos e os ARQUIVOS das imagens — links
# morrem quando a plataforma sai do ar.
class EnterpriseExport
  def initialize(enterprise)
    @enterprise = enterprise
  end

  def to_zip
    Zip::OutputStream.write_buffer do |zip|
      zip.put_next_entry("LEIA-ME.txt")
      zip.write(readme)
      zip.put_next_entry("empreendimento.json")
      zip.write(JSON.pretty_generate(enterprise_data))
      zip.put_next_entry("vitrine.json")
      zip.write(JSON.pretty_generate(@enterprise.content))
      zip.put_next_entry("eventos.json")
      zip.write(JSON.pretty_generate(events_data))
      images.each do |name, blob|
        zip.put_next_entry("imagens/#{name}")
        blob.download { |chunk| zip.write(chunk) }
      end
    end.string
  end

  private

  def enterprise_data
    {
      "exportado_em" => Time.current.iso8601,
      "nome" => @enterprise.name,
      "endereco_da_pagina" => @enterprise.slug,
      "descricao_curta" => @enterprise.short_description,
      "bairro" => @enterprise.neighborhood,
      "whatsapp" => @enterprise.whatsapp,
      "instagram" => @enterprise.instagram,
      "situacao" => @enterprise.published? ? "publicada" : "rascunho",
      "publicada_em" => @enterprise.published_at&.iso8601,
      "criada_em" => @enterprise.created_at.iso8601,
      "membros" => @enterprise.users.map { |u| { "nome" => u.name, "telefone" => u.phone } },
      "imagens" => images.keys
    }
  end

  def events_data
    Event.where(subject: @enterprise).order(:id).map do |e|
      { "tipo" => e.kind, "quando" => e.occurred_at.iso8601, "detalhes" => e.payload }
    end
  end

  def images
    @images ||= begin
      list = {}
      list["perfil#{ext(@enterprise.profile_image.blob)}"] = @enterprise.profile_image.blob if @enterprise.profile_image.attached?
      list["capa#{ext(@enterprise.cover_image.blob)}"] = @enterprise.cover_image.blob if @enterprise.cover_image.attached?
      @enterprise.content_images.includes(file_attachment: :blob).order(:id).each do |image|
        list["conteudo-#{image.id}#{ext(image.file.blob)}"] = image.file.blob
      end
      list
    end
  end

  def ext(blob) = ".#{blob.filename.extension_without_delimiter.presence || 'jpg'}"

  def readme
    <<~TXT
      Exportação do empreendimento "#{@enterprise.name}" — Feira Solidária
      Gerada em #{I18n.l(Time.current, format: :long)}.

      Estes dados são seus. Este arquivo contém tudo o que a plataforma guarda
      sobre o seu empreendimento:

      empreendimento.json  dados cadastrais e lista de membros
      vitrine.json         o conteúdo da sua página, no formato em que é guardado (EditorJS)
      eventos.json         o histórico de tudo que aconteceu com o empreendimento na plataforma
      imagens/             as fotos originais que você enviou

      Formato aberto (JSON e JPEG/PNG), legível por qualquer programa.
    TXT
  end
end
