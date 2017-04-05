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
