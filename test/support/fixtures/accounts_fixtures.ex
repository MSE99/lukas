defmodule Lukas.AccountsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Lukas.Accounts` context.
  """

  alias Lukas.Accounts

  def unique_user_phone_number,
    do: "#{System.unique_integer([:positive]) |> Integer.to_string() |> String.duplicate(2)}"

  def unique_user_email, do: "user#{System.unique_integer()}@example.com"
  def valid_user_password, do: "hello world!"

  def valid_user_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      phone_number: unique_user_phone_number(),
      email: unique_user_email(),
      password: valid_user_password(),
      kind: :operator,
      name: "Name ##{System.unique_integer([:positive])}"
    })
  end

  def student_fixture(attrs \\ %{}) do
    attrs
    |> Map.put(:kind, :student)
    |> user_fixture()
  end

  def lecturer_fixture(attrs \\ %{}) do
    full_attrs =
      Enum.into(attrs, %{
        "phone_number" => unique_user_phone_number(),
        "email" => unique_user_email(),
        "password" => valid_user_password(),
        "kind" => "lecturer",
        "name" => "Name ##{System.unique_integer([:positive])}"
      })

    inv = invite_fixture()
    {:ok, lect} = Lukas.Accounts.register_user(inv, full_attrs)
    lect
  end

  def user_fixture(attrs \\ %{}) do
    {:ok, user} =
      attrs
      |> valid_user_attributes()
      |> Lukas.Accounts.register_user()

    user
  end

  def extract_user_token(fun) do
    {:ok, captured_email} = fun.(&"[TOKEN]#{&1}[TOKEN]")
    [_, token | _] = String.split(captured_email.text_body, "[TOKEN]")
    token
  end

  def invite_fixture() do
    Accounts.generate_invite!()
  end
end
