defmodule Lukas.AccountsFixtures do
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
      name: "Name ##{System.unique_integer([:positive])}"
    })
  end

  def student_fixture(attrs \\ %{}) do
    {:ok, student} =
      attrs
      |> valid_user_attributes()
      |> Accounts.register_student()

    student
  end

  def lecturer_fixture(attrs \\ %{}) do
    full_attrs = attrs |> valid_user_attributes()
    inv = lecturer_invite_fixture()
    {:ok, lect} = Lukas.Accounts.register_lecturer(inv, full_attrs)
    lect
  end

  def user_fixture(attrs \\ %{}) do
    {:ok, operator} =
      attrs
      |> valid_user_attributes()
      |> Accounts.register_operator()

    operator
  end

  def extract_user_token(fun) do
    {:ok, captured_email} = fun.(&"[TOKEN]#{&1}[TOKEN]")
    [_, token | _] = String.split(captured_email.text_body, "[TOKEN]")
    token
  end

  def lecturer_invite_fixture() do
    Accounts.generate_lecturer_invite!()
  end

  def operator_invite_fixture() do
    Accounts.generate_operator_invite!()
  end
end
