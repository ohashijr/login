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
