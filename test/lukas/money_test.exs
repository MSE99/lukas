defmodule Lukas.MoneyTest do
  use Lukas.DataCase

  import Lukas.AccountsFixtures
  import Lukas.MoneyFixtures
  import Lukas.LearningFixtures

  alias Lukas.Money

  setup do
    %{student: student_fixture(), clerk: user_fixture()}
  end

  test "get_deposited_amount/1 should return 0", %{student: student} do
    assert Money.get_deposited_amount!(student) == 0
  end

  test "get_deposited_amount/1 should return 1000 (for 2 deposits)", %{
    student: student,
    clerk: clerk
  } do
    direct_deposit_fixture(clerk, student, 500)
    direct_deposit_fixture(clerk, student, 500)

    assert Money.get_deposited_amount!(student) == 1000.0
  end

  test "get_deposited_amount/1 should return 500 (for 2 500 deposits & 1 500 purchase)", %{
    student: student,
    clerk: clerk
  } do
    direct_deposit_fixture(clerk, student, 500)
    direct_deposit_fixture(clerk, student, 500)

    course = course_fixture(%{price: 500.0})
    purchase_fixture(student, course)

    assert Money.get_deposited_amount!(student) == 500.0
  end

  test "get_deposited_amount/1 should return 50 (10 400 deposits and 1 50 deposit and 10 400 purchase)",
       %{
         student: student,
         clerk: clerk
       } do
    Enum.each(1..10, fn _ -> direct_deposit_fixture(clerk, student, 400) end)

    direct_deposit_fixture(clerk, student, 50.0)

    Enum.each(1..10, fn _ -> purchase_fixture(student, course_fixture(%{price: 400})) end)

    assert Money.get_deposited_amount!(student) == 50.0
  end

  test "purchase_course/2 should emit a purchase added event to wallets/:user_id", %{
    student: student,
    clerk: clerk
  } do
    Money.watch_wallet(student)

    course = course_fixture(%{price: 500.0})

    direct_deposit_fixture(clerk, student, 1000)

    Money.purchase_course_for(student, course)

    assert Money.get_deposited_amount!(student) == 500.0

    student_id = student.id

    assert_received({:wallet, ^student_id, :purchase_made, purchase})

    assert purchase.amount == 500.0
  end

  test "directly_deposit_to_student/3 should emit a wallet post deposit", %{
    student: student,
    clerk: clerk
  } do
    Money.watch_wallet(student)

    Money.directly_deposit_to_student!(clerk, student, 10_000.0)

    student_id = student.id

    assert_received({:wallet, ^student_id, :deposit_made, deposit})

    assert deposit.amount == 10_000.0
  end
end
