# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Lukas.Repo.insert!(%Lukas.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

{:ok, clerk} =
  Lukas.Accounts.register_user(%{
    "kind" => "operator",
    "phone_number" => "091",
    "password" => "123123123123",
    "email" => "cool2@gmail.com",
    "name" => "Mohamed Edrah"
  })

{:ok, student} =
  Lukas.Accounts.register_user(%{
    "kind" => "student",
    "phone_number" => "092",
    "password" => "123123123123",
    "email" => "cool@gmail.com",
    "name" => "Abu bakr sadiq"
  })

Lukas.Money.directly_deposit_to_student!(clerk, student, 5000)

1..15
|> Enum.each(fn _ ->
  {:ok, student} =
    Lukas.Accounts.register_user(%{
      "kind" => "student",
      "phone_number" => "092 #{System.unique_integer([:positive])}",
      "password" => "123123123123",
      "email" => "mail_#{System.unique_integer([:positive])}@gmail.com",
      "name" => "Student #{System.unique_integer([:positive])}"
    })
end)

{:ok, _} =
  Lukas.Accounts.register_user(%{
    "kind" => "lecturer",
    "phone_number" => "094",
    "password" => "123123123123",
    "email" => "cool3@gmail.com",
    "name" => "Ali ageel"
  })
