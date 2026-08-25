# ADR 0010 — Imagens: disco local, proxy, variantes pré-processadas, sem EXIF

**Data:** 2026-08-25 · **Estado:** aceita

## Contexto

Fotos vêm de celular com 4–8 MB (Epic 1.4). O público está em Android barato e 3G
(§3.6); peso de página é requisito. EXIF de foto de celular carrega coordenadas GPS —
publicar isso seria expor a residência de quem mora em área de vulnerabilidade (Epic 1.1).

## Decisão

- **Active Storage com serviço de disco** no volume do Kamal (`/var/lib/feira/storage`),
  incluído no backup diário. Sem object storage para imagens por enquanto: 30 lojas × 12
  fotos cabem em disco, e o dado fica na máquina da rede.
- **Proxy, não redirect** (`resolve_model_to_route = :rails_storage_proxy`): uma requisição
  por imagem em vez de duas. Custa CPU do Puma (1 vCPU); reavaliar com tráfego real —
  a alternativa é cache no nginx do host.
- **Variantes nomeadas, pré-processadas** em job (Solid Queue, dentro do Puma): `thumb`
  320², `profile` 400², `cover` 1200×630, `content` ≤ 1600. JPEG q80. Quem visita nunca
  paga o processamento.
- **`strip` de metadados** em toda variante: sai EXIF, sai GPS. O original fica guardado
  (é da pessoa, vai no export) mas nunca é servido publicamente.
- **Formatos aceitos:** JPEG, PNG, WebP. **HEIC (iPhone) não**: exige libheif no vips; o
  erro diz "envie em JPG". Público-alvo é Android; reavaliar se aparecer demanda.
- **Limites:** 10 MB por arquivo (o critério pede 6 MB aceitos), 12 fotos de conteúdo por
  empreendimento, mais perfil e capa. Mensagens de erro dizem o que fazer.
- `ContentImage` mede largura/altura na criação para `<img width height>` — evita salto de
  layout em conexão lenta.

## Alternativas consideradas

- **S3/R2/B2 para imagens.** Mais robusto, mas terceiro no caminho e custo variável;
  desnecessário nesta escala. O backup remoto (ADR 0003) já cobre o risco de perda.
- **WebP nas variantes.** 25–30% menor, mas Safari antigo e alguns Androids velhos não
  abrem. JPEG é o mínimo denominador; revisitar.
- **Redimensionar no cliente (JS).** Pouparia upload em 3G, mas depende de JS e de
  navegador; fica como melhoria, não substituto do processamento no servidor.

## Consequências

- `libvips` é dependência de sistema (já no `Dockerfile`; local via apt).
- Teste de tese: JPEG > 6 MB é aceito e a variante sai com fração do peso e ≤ 1600 px.
