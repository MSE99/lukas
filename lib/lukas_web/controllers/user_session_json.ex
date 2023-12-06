defmodule LukasWeb.UserSessionJSON do
  def whoami(%{user: user}) do
    user
  end
end
