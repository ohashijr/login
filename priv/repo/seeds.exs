# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Login.Repo.insert!(%Login.SomeModel{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

Login.Repo.delete_all Login.User

Login.User.changeset(%Login.User{}, %{name: "Maria", email: "maria@gmail.com", password: "phoenix", password_confirmation: "phoenix"})
|> Login.Repo.insert!

Login.User.changeset(%Login.User{}, %{name: "Joao", email: "joao@gmail.com", password: "phoenix", password_confirmation: "phoenix"})
|> Login.Repo.insert!
