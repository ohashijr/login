# Login

Neste tutorial iremos criar um sistema simples que realiza autenticação (coherence) e autorização (policy wonk), num exemplo de um blog simples.

* Gerar CRUD dos Post, cada post possui apenas o titulo e o corpo da mensagem.
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

* Criar a base de dados e migrar a tabela dos posts
```shell
mix ecto.create
mix ecto.migrate
```

* Adicionar a autenticação com o Coherence para proteger as ações do Post, no arquivo _mix.exs_, adicionar `{:coherence, "~> 0.3"}` nos _deps_ e na _application_ adicionar o `:coherence`.

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

* Instalar as dependencias

```shell
run mix deps.get
```

* Coherence pede para configurar as rotas, no arquivo _router.ex_ adicionar os seguintes comandos.

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

O Coherence adiciona algumas configurações no final do arquivo _config.ex_ , o que faz com que o trecho de codigo a baixo não fique no final do arquivo, corrigir isso.

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

* Para simplificar o exemplo, vamos proteger todas as ações do CRUD Post.

```elixir
scope "/", Login do
  pipe_through :protected
  # Add protected routes below
  resources "/posts", PostController
end
```

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

* Testar o sistema. Logar no sistema e acessar _http://localhost:4000/posts_ só usuário logado pode realizar as operações de criação, visualização, edição e deletar os posts.

Um problema é que usuários podem editar, visualizar e deletar posts de outros usuários. Vamos tratar disso na autorização com Policy Wonk

* Config Email - MAILGUN

# Autorização - Policy Wonk.

* Adicionar no arquivo _mix.exs_ a dependencia `{:policy_wonk, "~> 0.2"}`.

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
   {:coherence, "~> 0.3"},
   {:policy_wonk, "~> 0.2"}]
end
```

* Instalar a dependência

```shell
mix deps.get
```

* Configurar o Policy Wonk, no arquivo _config.exs_ adicionar:

```elixir
config :policy_wonk, PolicyWonk,
  policies: Login.Policies
```

* Criar o arquivo _/lib/policy_wonk/policies.ex_ , porém vamos sobre-escrever essa policy no controller.

```elixir
defmodule Login.Policies do
  use PolicyWonk.Enforce
  @behavior PolicyWonk.Policy

  @err_handler Login.ErrorHandlers

  def policy( assigns, :current_user) do
    case assigns[:current_user] do
      _user = %Login.User{} -> :ok
      _ -> :current_user
    end
  end

  def policy_error(conn, error_data) when is_bitstring(error_data), do: @err_handler.unauthorized(conn, error_data)

  def policy_error(conn, error_data), do: policy_error(conn, "Unauthorized")
end

```

* É necessário fazer a associação entre Posts e Users, gerar a migration:

```shell
mix ecto.gen.migration add_user_id_to_posts
```

```elixir
defmodule Login.Repo.Migrations.AddUserIdToPosts do
  use Ecto.Migration

  def change do
    alter table(:posts) do
      add :user_id, references(:users, on_delete: :delete_all)
    end
  end
end
```

* Associar no model Post, no arquivo _web/models/post.ex_ editar:

destaque: `belongs_to :user, Login.User` e `cast(params, [:title, :body, :user_id])`

```elixir
defmodule Login.Post do
  use Login.Web, :model

  schema "posts" do
    field :title, :string
    field :body, :string

    belongs_to :user, Login.User
    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:title, :body, :user_id])
    |> validate_required([:title, :body])
  end
end
```

* O arquivo _web/models/coherence/user.ex_ deve ficar assim:

destaque: `has_many :posts, Login.Post`

```elixir
defmodule Login.User do
  use Login.Web, :model
  use Coherence.Schema

  schema "users" do
    field :name, :string
    field :email, :string
    coherence_schema

    has_many :posts, Login.Post

    timestamps
  end

  def changeset(model, params \\ %{}) do
    model
    |> cast(params, [:name, :email] ++ coherence_fields)
    |> validate_required([:name, :email])
    |> validate_format(:email, ~r/@/)
    |> unique_constraint(:email)
    |> validate_coherence(params)
  end
end
```

* A relação entre as duas entidades foi estabelecida.
TODO testar no console as consultas

* O PostController não tem informação do User, precisamos adicionar. No _post_controller_ uma vez que vai acessar o model do User com bastante frequência, adicionar o alias:

```elixir
alias Login.{Post, User}
```

* Temos dois usuários no sistema, a maria e o joao. Vamos logar com o usuário maria, se acessarmos o link http://localhost:4000/posts veremos os posts de todos os funcionários, inclusive do joão. Para corrigir
isso é necessário alterar a consulta no arquivo _post_controller.ex_ .

```elixir
def index(conn, _params) do
  query = from p in Post,
          where: p.user_id == ^conn.assigns.current_user.id
  posts = Repo.all(query)
  render(conn, "index.html", posts: posts)
end
```

Em vez de consultar todos os usuários com a query `Repo.all(Post)`, alteramos para os posts apenas do usuário
logado no sistema.

* Na criação de um novo Post é necessário saber quem é o usuário que está logado no momento da criação, este será
o dono do Post

```elixir
def create(conn, %{"post" => post_params}) do
  post_params =
    post_params
    |> Map.put("user_id", conn.assigns.current_user.id)

  changeset = Post.changeset(%Post{}, post_params)

  case Repo.insert(changeset) do
    {:ok, _post} ->
      conn
      |> put_flash(:info, "Post created successfully.")
      |> redirect(to: post_path(conn, :index))
    {:error, changeset} ->
      render(conn, "new.html", changeset: changeset)
  end
end
```

* O trecho a baixo adicionar no map (post_params) o _user_id_ do usuário logado no sistema.
Dessa forma quando

```elixir
post_params =
  post_params
  |> Map.put("user_id", conn.assigns.current_user.id)
```

* Ainda no PostController, definindo a policy, error e load

```elixir
def policy(assigns, :post_owner) do
  case {assigns[:current_user], assigns[:post]} do
    {%User{id: user_id}, post=%Post{}} ->
      case post.user_id do
        ^user_id -> :ok
        _ -> :not_found
      end
    _ -> :not_found
  end
end

def policy_error(conn, :not_found) do
  Login.ErrorHandlers.resource_not_found(conn, :not_found)
end

def load_resource(_conn, :post, %{"id" => id}) do
  case Repo.get(Post, id) do
    nil -> :not_found
    post -> {:ok, :post, post}
  end
end
```

* Definindo o plug para carregar a policy e load

```elixir
plug PolicyWonk.LoadResource, [:post] when action in [:show, :edit, :update, :delete]
plug PolicyWonk.Enforce, :post_owner when action in [:show, :edit, :update, :delete]
```

* PostController completo

```elixir
defmodule Login.PostController do
  use Login.Web, :controller

  alias Login.{Post, User}

  plug PolicyWonk.LoadResource, [:post] when action in [:show, :edit, :update, :delete]
  plug PolicyWonk.Enforce, :post_owner when action in [:show, :edit, :update, :delete]

  def index(conn, _params) do
    query = from p in Post,
            where: p.user_id == ^conn.assigns.current_user.id
    posts = Repo.all(query)
    render(conn, "index.html", posts: posts)
  end

  def new(conn, _params) do
    changeset = Post.changeset(%Post{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"post" => post_params}) do
    post_params =
      post_params
      |> Map.put("user_id", conn.assigns.current_user.id)

    changeset = Post.changeset(%Post{}, post_params)

    case Repo.insert(changeset) do
      {:ok, _post} ->
        conn
        |> put_flash(:info, "Post created successfully.")
        |> redirect(to: post_path(conn, :index))
      {:error, changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  # conn, %{"id" => id}
  def show(conn=%{assigns: %{post: post}}, _params) do
    #post = Repo.get!(Post, id)
    render(conn, "show.html", post: post)
  end

  # conn, %{"id" => id}
  def edit(conn=%{assigns: %{post: post}}, _params) do
    #post = Repo.get!(Post, id)
    changeset = Post.changeset(post)
    render(conn, "edit.html", post: post, changeset: changeset)
  end

  # conn, %{"id" => id, "post" => post_params}
  def update(conn=%{assigns: %{post: post}}, %{"post" => post_params}) do
    #post = Repo.get!(Post, id)
    changeset = Post.changeset(post, post_params)

    case Repo.update(changeset) do
      {:ok, post} ->
        conn
        |> put_flash(:info, "Post updated successfully.")
        |> redirect(to: post_path(conn, :show, post))
      {:error, changeset} ->
        render(conn, "edit.html", post: post, changeset: changeset)
    end
  end

  def delete(conn=%{assigns: %{post: post}}, _params) do
    #post = Repo.get!(Post, id)

    # Here we use delete! (with a bang) because we expect
    # it to always work (and if it does not, it will raise).
    Repo.delete!(post)

    conn
    |> put_flash(:info, "Post deleted successfully.")
    |> redirect(to: post_path(conn, :index))
  end

  def policy(assigns, :post_owner) do
    case {assigns[:current_user], assigns[:post]} do
      {%User{id: user_id}, post=%Post{}} ->
        case post.user_id do
          ^user_id -> :ok
          _ -> :not_found
        end
      _ -> :not_found
    end
  end

  def policy_error(conn, :not_found) do
    Login.ErrorHandlers.resource_not_found(conn, :not_found)
  end

  def load_resource(_conn, :post, %{"id" => id}) do
    case Repo.get(Post, id) do
      nil -> :not_found
      post -> {:ok, :post, post}
    end
  end
end
```

Agora tds as ações estão protegidas.


* Referências
- http://oss.io/p/smpallen99/coherence
- http://www.programwitherik.com/user-authentication-with-the-phoenix-framework-and-coherence/
- http://www.agencymajor.com.br/coherence-e-exadmin-devise-e-activeadmin-para-phoenix/
- https://medium.com/@boydm/policy-wonk-the-tutorial-6d2b6e435c46#.l0p6epruz
