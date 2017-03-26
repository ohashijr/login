# Login

* Gerar CRUD dos Post
```elixir
mix phoenix.gen.html Post posts title body:text
```

* Adicionando as rotas, no arquivo _routes.ex_ adicionar, sem autenticação nenhuma primeiro
```elixir
scope "/", Login do
  pipe_through :browser
  get "/", PageController, :index
  resources "/posts", PostController
end
```
* Migrar a tabela dos posts
```elixir
mix ecto.migrate
```

Testar o CRUD dos posts, qualquer usuário pode realizar qualquer uma das operações.

* Adicionar o Coherence arquivo mix.exs

```elixir
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

```

* Executar os comandos

```bash
run mix deps.get

mix ecto.create
```
* Configurar o arquivo _router.ex_

```elixir
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
```

* Executar o comando, para gerar os arquivos de configuração, views, controllers, ... do Coherence

```shell
mix coherence.install --full-invitable
```

* Alterar o arquivo _config.ex_

O Coherence adiciona algumas configurações no arquivo _config.ex_ , o que faz com que o trecho de codigo a baixo não fique no final do arquivo, alterar as linhas para o final do arquivo.

```elixir
# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
```

* O Coherence cria um usuário para o sistema, vamos adicionar alguns usuários para teste. No arquivo _priv/repo/seeds.exs_ adicionar:

```elixir
Login.Repo.delete_all Login.User

Login.User.changeset(%Login.User{}, %{name: "Maria", email: "maria@gmail.com", password: "phoenix", password_confirmation: "phoenix"})
|> Login.Repo.insert!

Login.User.changeset(%Login.User{}, %{name: "Joao", email: "joao@gmail.com", password: "phoenix", password_confirmation: "phoenix"})
|> Login.Repo.insert!
```

* Migrar e rodar os seeds
```shell
mix ecto.setup
```

* Neste exemplo, o objetivo é que qualquer usuário do sistema consiga acessar os posts, porém
apenas usuários autenticados possam criar, editar ou deletar os posts. No arquivo router.ex
altere as seguintes linhas de código. É necessário inverter as regras, caso contrário o _/posts/new_ será mapeado para o _/posts/show_, a ordem das rotas é extremamente importante.

```elixir
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
```

Apenas os usuários logados no sistema conseguiram criar (new), alterar (edit) e deletar (delete) posts.

* Vamos adicionar o menu de navegação, no arquivo _web/templates/layout/app.html.eex_ , adicione o seguinte trecho de código no header.

```html
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
```

* Retirar o link de criação, quando o usuário não estiver logado. Alterar no arquivo
_/templates/post/index.html.ex_

```elixir
<%= if Coherence.logged_in?(@conn) do %>
  <%= link "New post", to: post_path(@conn, :new) %>
<% end %>
```

O edit e delete serão tratados na autorização.

Para acessar os posts é necessário estar logado no sistema, porém qualquer usuário pode acessar qualquer post.
Usuários não deveriam poder editar posts de outros usuários.

* Autorização - Policy Wonk




* Referências
- http://oss.io/p/smpallen99/coherence
- http://www.programwitherik.com/user-authentication-with-the-phoenix-framework-and-coherence/
- http://www.agencymajor.com.br/coherence-e-exadmin-devise-e-activeadmin-para-phoenix/
-
