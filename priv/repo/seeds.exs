inv = Lukas.Accounts.generate_operator_invite!()

{:ok, clerk} =
  Lukas.Accounts.register_operator(inv, %{
    "kind" => "operator",
    "phone_number" => "091",
    "password" => "123123123123",
    "email" => "cool2@gmail.com",
    "name" => "Mohamed Edrah"
  })

{:ok, student} =
  Lukas.Accounts.register_student(%{
    "kind" => "student",
    "phone_number" => "092",
    "password" => "123123123123",
    "email" => "cool@gmail.com",
    "name" => "Abu bakr sadiq"
  })

Lukas.Money.directly_deposit_to_student!(clerk, student, 5000)

invite = Lukas.Accounts.generate_lecturer_invite!()

{:ok, _} =
  Lukas.Accounts.register_lecturer(invite, %{
    "kind" => "lecturer",
    "phone_number" => "094",
    "password" => "123123123123",
    "email" => "cool3@gmail.com",
    "name" => "Ali ageel"
  })
