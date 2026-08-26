Rails.application.routes.draw do
  root "hub#index"

  # Português nas URLs que as pessoas veem (CLAUDE.md §3.6).
  resource :session, path: "entrar", only: %i[ new create destroy ], path_names: { new: "" }
  resource :account, path: "minha-conta", only: %i[ show update ]

  # "Próxima feira": dado da rede, editável por qualquer membro (Epic 1).
  resources :fair_events, path: "proxima-feira", only: %i[ index new create edit update ],
    path_names: { new: "nova", edit: "editar" }

  # Catálogo da feira e capacidade da rede (Epic 2).
  get "produtos", to: "catalog#index", as: :catalog
  get "capacidade-da-rede", to: "network_capacity#index", as: :network_capacity

  # Cesta e pedido (Epic 3): sem login, sem pagamento.
  resource :cart, path: "cesta", only: %i[ show ] do
    resources :items, path: "itens", only: %i[ create update destroy ], controller: "cart_items"
  end
  get "cesta/enviar", to: "checkouts#new", as: :new_checkout
  post "cesta/enviar", to: "checkouts#create", as: :checkout
  get "pedidos/enviados", to: "orders#sent", as: :sent_orders
  get "pedidos/:token", to: "orders#show", as: :order, constraints: { token: /[1-9A-HJ-NP-Za-km-z]{20}/ }
  post "pedidos/:token/whatsapp", to: "orders#whatsapp", as: :order_whatsapp, constraints: { token: /[1-9A-HJ-NP-Za-km-z]{20}/ }

  # Minha loja: tudo escopado por Current.enterprise (ADR 0005).
  scope path: "minha-loja", module: :my_enterprise, as: :my_enterprise do
    get "/", to: "enterprises#show", as: ""
    get "nova", to: "enterprises#new", as: :new
    post "/", to: "enterprises#create", as: :create
    get "editar", to: "enterprises#edit", as: :edit
    patch "/", to: "enterprises#update", as: :update
    get "previa", to: "enterprises#preview", as: :preview
    post "publicar", to: "enterprises#publish", as: :publish
    post "despublicar", to: "enterprises#unpublish", as: :unpublish
    get "exportar", to: "enterprises#export", as: :export
    get "escolher", to: "choices#index", as: :choices
    post "escolher", to: "choices#create", as: :choose
    resources :memberships, path: "membros", only: %i[ index create destroy ]
    resources :content_images, path: "imagens", only: %i[ create ]
    resources :products, path: "produtos", except: %i[ show ], path_names: { new: "novo", edit: "editar" } do
      member do
        post :publish, path: "publicar"
        post :pause, path: "pausar"
        post :unpause, path: "despausar"
      end
      resources :photos, path: "fotos", only: %i[ destroy ], controller: "product_photos"
    end
    resources :orders, path: "pedidos", only: %i[ index show ] do
      member do
        post :confirm, path: "confirmar"
        post :complete, path: "concluir"
        post :refuse, path: "recusar"
        post :cancel, path: "cancelar"
      end
    end
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  get "up" => "rails/health#show", as: :rails_health_check

  # Vitrine pública: endereço curto e falável. Última rota.
  get "/:slug", to: "enterprises#show", as: :enterprise, constraints: { slug: /[a-z]+(?:-[a-z]+)*/ }
end
