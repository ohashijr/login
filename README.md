# Login

* mix.exs
defp deps do
  [{:phoenix, "~> 1.2.1"},
   {:phoenix_pubsub, "~> 1.0"},
   {:phoenix_ecto, "~> 3.0"},
   {:postgrex, ">= 0.0.0"},
   {:phoenix_html, "~> 2.6"},
   {:phoenix_live_reload, "~> 1.0", only: :dev},
   {:gettext, "~> 0.11"},
   {:cowboy, "~> 1.0"},
   {:coherence, "~> 0.3"}]
end

def application do
  [mod: {Login, []},
   applications: [:coherence, :phoenix, :phoenix_pubsub, :phoenix_html, :cowboy, :logger, :gettext,
                  :phoenix_ecto, :postgrex]]
end

// run mix deps.get

// mix ecto.create

* router.ex
defmodule Login.Router do
  use Login.Web, :router
  use Coherence.Router         # Add this

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug Coherence.Authentication.Session  # Add this
  end

  pipeline :protected do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug Coherence.Authentication.Session, protected: true  # Add this
  end

  # Add this block
  scope "/" do
    pipe_through :browser
    coherence_routes
  end

  # Add this block
  scope "/" do
    pipe_through :protected
    coherence_routes :protected
  end

  scope "/", Login do
    pipe_through :browser
    get "/", PageController, :index
    # Add public routes below

  end

  scope "/", Login do
    pipe_through :protected
    # Add protected routes below

  end

end

* mix coherence.install --full-invitable

* priv/repo/seeds.exs

Login.Repo.delete_all Login.User

Login.User.changeset(%Login.User{}, %{name: "Test User", email: "testuser@example.com", password: "secret", password_confirmation: "secret"})
|> Login.Repo.insert!

* config.ex

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"


* mix ecto.setup
  migrate and generate seeds

* Gerar Posts
mix phoenix.gen.html Post posts title body:text

* add routes
resources "/posts", PostController

mix ecto.migrate

* web/templates/layout/app.html.eex
<header class="header">
  <nav role="navigation">
    <ul class="nav nav-pills pull-right">
      <%= if Coherence.current_user(@conn) do %>
        <%= if @conn.assigns[:remembered] do %>
          <li style="color: red;">!!</li>
        <% end %>
      <% end %>
      <%= Login.Coherence.ViewHelpers.coherence_links(@conn, :layout) %>
      <li><a href="http://www.phoenixframework.org/docs">Get Started</a></li>
    </ul>
  </nav>
  <span class="logo"></span>
</header>

O correto seria que qualquer usuário do sistema conseguisse acessar os posts, porém
não fosse possivel criar, editar ou deletar os mesmos.

* router.ex

é necessário inverter as regras, senão o /posts/new será mapeado para o /posts/show

scope "/", Login do
  pipe_through :protected
  # Add protected routes below
  resources "/posts", PostController, except: [:index, :show]
end

scope "/", Login do
  pipe_through :browser
  get "/", PageController, :index
  # Add public routes below
  resources "/posts", PostController, only: [:index, :show]
end

* mostrar os links new, editar e delete apenas para os usuários logados no sistema

/templates/post/index.html.ex

Só mostrar o link de novo post se o usuário estiver logado.

<%= if Coherence.logged_in?(@conn) do %>
  <%= link "New post", to: post_path(@conn, :new) %>
<% end %>

O edit e delete serão tratados na autorização.

Para acessar os posts é necessário estar logado no sistema, porém qualquer usuário pode acessar qualquer post.
Usuários não deveriam poder editar posts de outros usuários.

* Autorização - Policy Wonk




* Referências
- http://oss.io/p/smpallen99/coherence
- http://www.programwitherik.com/user-authentication-with-the-phoenix-framework-and-coherence/
- http://www.agencymajor.com.br/coherence-e-exadmin-devise-e-activeadmin-para-phoenix/
-
