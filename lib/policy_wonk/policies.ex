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

  def policy( assigns, {:user_perm, perms}) when is_list(perms) do
    case assigns[:current_user] do
      nil -> :current_user
      user ->
        case user.permissions do
          nil -> {:user_perm, perms} # fail no permissions
          user_perms ->
            Enum.all?(perms, &(Enum.member?(user_perms, to_string(&1))) )
            |> case do
              true -> :ok
              false -> {:user_perm, perms} #fail missing perms
            end
        end
    end
  end

  def policy( assigns, {:user_perm, one_perm} ), do: policy( assigns, {:user_perm, [one_perm]} )

  def policy_error(conn, error_data) when is_bitstring(error_data), do: @err_handler.unauthorized(conn, error_data)

  def policy_error(conn, error_data), do: policy_error(conn, "Unauthorized")
end
