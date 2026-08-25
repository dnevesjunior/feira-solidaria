import { Controller } from "@hotwired/stimulus"

// EditorJS com allowlist de blocos (ADR 0009). O que este controller permite
// aqui é o mesmo que EditorJs::Document aceita no servidor — e o servidor é
// quem manda: qualquer coisa fora da lista é rejeitada lá.
export default class extends Controller {
  static targets = ["holder", "input"]
  static values = { uploadUrl: String }

  async connect() {
    // Import dinâmico: o EditorJS (~400 KB) só é baixado nesta página.
    const [EditorJS, Header, List, Quote, ImageTool] = await Promise.all([
      import("@editorjs/editorjs"), import("@editorjs/header"), import("@editorjs/list"),
      import("@editorjs/quote"), import("@editorjs/image")
    ]).then(mods => mods.map(m => m.default))
    const lib = { EditorJS, Header, List, Quote, ImageTool }
    const csrf = document.querySelector("meta[name=csrf-token]")?.content

    this.editor = new lib.EditorJS({
      holder: this.holderTarget,
      data: this.initialData(),
      placeholder: "Conte a história do seu empreendimento…",
      minHeight: 120,
      inlineToolbar: ["bold", "italic", "link"],
      tools: {
        header: { class: lib.Header, config: { levels: [2, 3], defaultLevel: 2, placeholder: "Título" } },
        list: { class: lib.List, inlineToolbar: true, config: { defaultStyle: "unordered" } },
        quote: { class: lib.Quote, inlineToolbar: true, config: { quotePlaceholder: "Frase", captionPlaceholder: "Quem disse" } },
        image: {
          class: lib.ImageTool,
          config: {
            endpoints: { byFile: this.uploadUrlValue },
            field: "image",
            types: "image/jpeg,image/png,image/webp",
            additionalRequestHeaders: { "X-CSRF-Token": csrf },
            captionPlaceholder: "Legenda (opcional)",
            buttonContent: "Escolher foto",
            features: { border: false, background: false, stretch: false }
          }
        }
      },
      i18n: {
        messages: {
          ui: {
            blockTunes: { toggler: { "Click to tune": "Toque para ajustar", "or drag to move": "ou arraste para mover" } },
            inlineToolbar: { converter: { "Convert to": "Converter em" } },
            toolbar: { toolbox: { Add: "Adicionar", Filter: "Filtrar", "Nothing found": "Nada encontrado" } },
            popover: { Filter: "Filtrar", "Nothing found": "Nada encontrado", "Convert to": "Converter em" }
          },
          toolNames: { Text: "Texto", Heading: "Título", List: "Lista", Quote: "Citação", Image: "Foto", Bold: "Negrito", Italic: "Itálico", Link: "Link" },
          tools: {
            list: { Unordered: "Com marcadores", Ordered: "Numerada", Checklist: "Lista de tarefas" },
            image: { "Select an Image": "Escolher foto", Caption: "Legenda", "With border": "Com borda", "Stretch image": "Esticar", "With background": "Com fundo" },
            link: { "Add a link": "Adicionar link" },
            header: { Heading: "Título" }
          },
          blockTunes: {
            delete: { Delete: "Apagar", "Click to delete": "Toque para apagar" },
            moveUp: { "Move up": "Mover para cima" },
            moveDown: { "Move down": "Mover para baixo" }
          }
        }
      }
    })
  }

  disconnect() {
    this.editor?.destroy?.()
  }

  initialData() {
    try {
      const data = JSON.parse(this.inputTarget.value || "{}")
      return { blocks: Array.isArray(data.blocks) ? data.blocks : [] }
    } catch {
      return { blocks: [] }
    }
  }

  // Serializa o editor no campo oculto antes de o formulário sair.
  async save(event) {
    if (!this.editor || this.saved) return
    event.preventDefault()
    const form = event.target.form
    const output = await this.editor.save()
    // Só o que o servidor conhece: o resto seria rejeitado lá de qualquer jeito.
    const blocks = output.blocks.map(({ type, data }) => ({ type, data }))
    this.inputTarget.value = JSON.stringify({ blocks })
    this.saved = true
    form.requestSubmit()
  }
}
