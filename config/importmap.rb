# Pin npm packages by running ./bin/importmap

pin "application"
# EditorJS: importado dinamicamente pelo editor_controller só em "Editar minha
# página"; sem preload (peso — CLAUDE.md §3.6).
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"
pin "@editorjs/editorjs", to: "@editorjs--editorjs.js", preload: false # @2.31.6
pin "@editorjs/header", to: "@editorjs--header.js", preload: false # @2.8.9
pin "@editorjs/image", to: "@editorjs--image.js", preload: false # @2.10.3
pin "@editorjs/list", to: "@editorjs--list.js", preload: false # @2.0.9
pin "@editorjs/quote", to: "@editorjs--quote.js", preload: false # @2.7.6
